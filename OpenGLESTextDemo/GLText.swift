//
//  GLText.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-09-06.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

class GLText {
    
    private static let CHAR_START = 32
    private static let CHAR_END = 126
    private static let CHAR_CNT = (((CHAR_END - CHAR_START) + 1) + 1)
    
    private static let CHAR_NONE = 32
    private static let CHAR_UNKNOWN = (CHAR_CNT - 1)
    
    private static let FONT_SIZE_MIN = 6
    private static let FONT_SIZE_MAX = 180
    
    static let CHAR_BATCH_SIZE = 24
    
    private var batch: SpriteBatch? = nil
    
    var fontPadX, fontPadY: Int
    
    var fontHeight: Float
    var fontAscent: Float
    var fontDescent: Float
    
    var textureInfo: GLKTextureInfo? = nil
    var textureSize: Int
    var textureRgn: TextureRegion? = nil
    
    var charWidthMax: Float
    var charHeight: Float
    var charWidths: [Float] = []
    var charRgn: [TextureRegion] = []
    var cellWidth, cellHeight: Int
    var rowCnt, colCnt: Int
    
    var scaleX, scaleY: Float
    var spaceX: Float
    
    private var mProgram: Program? = nil
    private var mColorHandle: GLint = 0
    private var mTextureUniformHandle: Int32 = 0
    
    init(program: Program? = nil) {
        
        if program == nil {
            mProgram = BatchTextProgram()
            mProgram?.initialize()
        } else {
            mProgram = program
        }
        
        batch = SpriteBatch(GLText.CHAR_BATCH_SIZE, mProgram!)
        
        // initialize remaining members
        fontPadX = 0
        fontPadY = 0
        
        fontHeight = 0.0
        fontAscent = 0.0
        fontDescent = 0.0
        
        textureSize = 0
        
        charWidthMax = 0
        charHeight = 0
        
        cellWidth = 0
        cellHeight = 0
        rowCnt = 0
        colCnt = 0
        
        scaleX = 1.0
        scaleY = 1.0
        spaceX = 0.0
        
        mColorHandle = glGetUniformLocation(mProgram!.getHandle(), "u_Color")
        mTextureUniformHandle = glGetUniformLocation(mProgram!.getHandle(), "u_Texture")
    }
    
    /**
        This will load the specified font file, create a texture for the defined
        character range, and setup all required values used to render with it.

        - Parameters:
        - file:       Name of the font to use.
        - size:       Requested pixel size of font (height)
        - padX, padY: Extra padding per character (X+Y Axis); to prevent overlapping characters.
        - Returns:    true if successful; otherwise false
     */
    func load(file: String, _ size: Int, _ padX: Int, _ padY: Int) -> Bool {
        
        fontPadX = padX
        fontPadY = padY
        
        // load the font
        let font = UIFont(name: file, size: CGFloat(size))
        
        // get font metrics
        fontHeight = Float((font?.lineHeight)!)
        fontAscent = Float((font?.ascender)!)
        fontDescent = Float((font?.descender)!)
        
        // determine the width of each character (including unknown character)
        // also determine the maximum character width
        charWidthMax = 0
        charHeight = 0
        for c in GLText.CHAR_START..<GLText.CHAR_END + 1 {
            let s = String(UnicodeScalar(c))
            
            var width = Float((s as NSString).sizeWithAttributes([NSFontAttributeName: font!]).width)
            width = ceilf(width)
        
            charWidths.append(width)
            if width > charWidthMax {
                charWidthMax = width
            }
        }
        
        var s = String(UnicodeScalar(GLText.CHAR_NONE))
        var width = Float((s as NSString).sizeWithAttributes([NSFontAttributeName: font!]).width)
        width = ceilf(width)
        charWidths.append(width)
        if width > charWidthMax {
            charWidthMax = width
        }
        
        // set character height to font height
        charHeight = fontHeight
        
        // find the maximum size, validate, and setup cell sizes
        cellWidth = Int(charWidthMax) + (2 * fontPadX)
        cellHeight = Int(charHeight) + (2 * fontPadY)
        let maxSize = cellWidth > cellHeight ? cellWidth : cellHeight
        if maxSize < GLText.FONT_SIZE_MIN || maxSize > GLText.FONT_SIZE_MAX {
            return false
        }
        
        // set texture size based on max font size (width or height)
        // NOTE: these values are fixed, based on the defined characters. when
        // changing start/end characters (CHAR_START/CHAR_END) this will need adjustment too!
        if maxSize <= 24 {
            textureSize = 256
        } else if maxSize <= 40 {
            textureSize = 512
        } else if maxSize <= 80 {
            textureSize = 1024
        } else {
            textureSize = 2048
        }
        
        // calculate rows/columns
        // NOTE: while not required for anything, these may be useful to have :)
        colCnt = textureSize / cellWidth
        rowCnt = Int(ceilf(Float(GLText.CHAR_CNT) / Float(colCnt)))
        
        // create an empty bitmap
        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bitmapInfo = CGBitmapInfo.AlphaInfoMask.rawValue & CGImageAlphaInfo.Only.rawValue
        let context = CGBitmapContextCreate(nil, textureSize, textureSize, 8, textureSize, colorSpace, bitmapInfo)
        
        CGContextSetAllowsAntialiasing(context, true)
        
        // Move 0,0 to top left corner, flip y axis
        CGContextTranslateCTM(context, 0, CGFloat(textureSize))
        CGContextScaleCTM(context, 1, -1)
        
        CGContextSetRGBFillColor(context, 0, 0, 0, 0)
        CGContextFillRect(context, CGRectMake(0, 0, CGFloat(textureSize), CGFloat(textureSize)))
        
        CGContextSetRGBFillColor(context, 1, 1, 1, 1)
        
        // render each of the characters to the bitmap (ie. build the font map)
        let fontRef = CTFontCreateWithName(font!.fontName as CFString, font!.pointSize, nil)
        var x: Float = Float(fontPadX)
        var y: Float = Float(fontAscent) + Float(fontPadY)
        for c in GLText.CHAR_START..<GLText.CHAR_END + 1 {
            
            let s = String(UnicodeScalar(c))
            drawChar(context!, fontRef, s, CGFloat(x), CGFloat(y))
            
            x += Float(cellWidth)
            if (Int(x) + cellWidth - fontPadX) > textureSize {
                x = Float(fontPadX)
                y += Float(cellHeight)
            }
        }
        s = String(UnicodeScalar(GLText.CHAR_NONE))
        drawChar(context!, fontRef, s, CGFloat(x), CGFloat(y))
        
        let contextImage = CGBitmapContextCreateImage(context)
        let fontImage: UIImage? = UIImage(CGImage: contextImage!)
        
        // save the bitmap in a texture
        textureInfo = TextureHelper.loadTexture(fontImage!)
        
        print("textureInfo : [", textureInfo, "]")
        
        // setup the array of character texture regions
        x = 0
        y = Float(fontPadY)
        for _ in 0..<GLText.CHAR_CNT {
            charRgn.append(TextureRegion(Float(textureSize), Float(textureSize), x, y, Float(cellWidth) - 1, Float(cellHeight) - 1))
            x += Float(cellWidth)
            if (Int(x) + cellWidth > textureSize) {
                x = 0
                y += Float(cellHeight)
            }
        }
        
        // create full texture region
        textureRgn = TextureRegion(Float(textureSize), Float(textureSize), 0, 0, Float(textureSize), Float(textureSize))
        
        return true
    }
    
    /**
        --Begin/End Text Drawing--
        Call these methods before/after (respectively all draw() calls using a text instance.
        NOTE: color is set on a per-batch basis, and fonts should be 8-bit alpha only!!!
     
        - Parameters:
        - red, green, blue: RGB values for font (default = 1.0)
        - alpha:            optional alpha value for font (default = 1.0)
        - vpMatrix:         View and projection matrix to use
     */
    func begin(vpMatrix: GLKMatrix4) {
        
        begin(1.0, 1.0, 1.0, 1.0, vpMatrix)
    }
    
    func begin(alpha: Float, _ vpMatrix: GLKMatrix4) {
        
        begin(1.0, 1.0, 1.0, alpha, vpMatrix)
    }
    
    func begin(red: Float, _ green: Float, _ blue: Float, _ alpha: Float, _ vpMatrix: GLKMatrix4) {
        
        initDraw(red, green, blue, alpha)
        batch!.beginBatch(vpMatrix)
    }
    
    func end() {
        
        batch!.endBatch()
    }
    
    /**
        --Draw Text--
        Draw text at the specified x,y position
     
        - Parameters:
        - text:     the string to draw
        - x, y, z:  the x, y, z position to draw text at (bottom left of text; including descent)
        - angleDeg: angle to rotate the text
     */
    func draw(text: String, _ x: Float, _ y: Float, _ z: Float, _ angleDegX: Float, _ angleDegY: Float, _ angleDegZ: Float) {
        
        let chrHeight = Float(cellHeight) * scaleY
        let chrWidth = Float(cellWidth) * scaleX
        let len = text.characters.count
        let x1 = x + (chrWidth / 2.0) - (Float(fontPadX) * scaleX)
        let y1 = y + (chrHeight / 2.0) - (Float(fontPadY) * scaleY)
    
        // create a model matrix based on x, y and angleDeg
        var modelMatrix: GLKMatrix4 = GLKMatrix4Identity
        modelMatrix = GLKMatrix4Translate(modelMatrix, x1, y1, z)
        modelMatrix = GLKMatrix4RotateZ(modelMatrix, GLKMathDegreesToRadians(angleDegZ))
        modelMatrix = GLKMatrix4RotateX(modelMatrix, GLKMathDegreesToRadians(angleDegX))
        modelMatrix = GLKMatrix4RotateY(modelMatrix, GLKMathDegreesToRadians(angleDegY))
    
        var letterX: Float = 0
        let letterY: Float = 0
        
        let text1 = text as NSString
        for i in 0..<len {
            var c = Int(text1.characterAtIndex(i)) - GLText.CHAR_START
            if c < 0 || c >= GLText.CHAR_CNT {
                c = GLText.CHAR_UNKNOWN
            }
            batch?.drawSprite(letterX, letterY, chrWidth, chrHeight, charRgn[c], modelMatrix)
            letterX += (charWidths[c] + spaceX) * scaleX
        }
    }
    
    func draw(text: String, _ x: Float, _ y: Float, _ z: Float, _ angleDegZ: Float) {
        
        draw(text, x, y, z, 0, 0, angleDegZ)
    }
    
    func draw(text: String, _ x: Float, _ y: Float, _ angleDegZ: Float) {
        
        draw(text, x, y, 0, angleDegZ)
    }
    
    func draw(text: String, _ x: Float, _ y: Float) {
        
        draw(text, x, y, 0, 0)
    }
    
    /**
        --Draw Text Centered--
        Draw text CENTERED at the specified x,y position.
     
        - Parameters:
        - text:     the string to draw
        - x, y, z:  the x, y, z position to draw text at (bottom left of text)
        - angleDeg: angle to rotate the text
        - Returns:    the total width of the text that was drawn
     */
    func drawC(text: String, _ x: Float, _ y: Float, _ z: Float,
               _ angleDegX: Float, _ angleDegY: Float, _ angleDegZ: Float) -> Float {
        
        let len: Float = getLength(text)
        draw(text, x - (len / 2.0), y - (getCharHeight() / 2.0), z, angleDegX, angleDegY, angleDegZ)
        return len
    }
    
    func drawC(text: String, _ x: Float, _ y: Float, _ z: Float, _ angleDegZ: Float) -> Float {
    
        return drawC(text, x, y, z, 0, 0, angleDegZ)
    }
    
    func drawC(text: String, _ x: Float, _ y: Float, _ angleDeg: Float) -> Float {
        
        return drawC(text, x, y, 0, angleDeg)
    }
    
    func drawC(text: String, _ x: Float, _ y: Float) -> Float {
        
        let len: Float = getLength(text)
        return drawC(text, x - (len / 2.0), y - (getCharHeight() / 2.0), 0)
    }
    
    func drawCX(text: String, _ x: Float, _ y: Float) -> Float {
        
        let len: Float = getLength(text)
        draw(text, x - (len / 2.0), y)
        return len
    }
    
    func drawCY(text: String , _ x: Float, _ y: Float) {
        
        draw(text, x, y - (getCharHeight() / 2.0))
    }
    
    /**
        --Set Scale--
        Set the scaling to use for the font.
     
        - Parameters:
        - scale:  uniform scale for both x and y axis scaling
        - sx, sy: separate x and y axis scaling factors
     */
    func setScale(scale: Float) {
        
        scaleX = scale
        scaleY = scale
    }
    
    func setScale(sx: Float, _ sy: Float) {
        
        scaleX = sx
        scaleY = sy
    }
    
    /**
        --Get Scale--
        Get the current scaling used for the font.
     
        - Returns: the x/y scale currently used for scale
     */
    func getScaleX() -> Float {
        
        return scaleX
    }
    
    func getScaleY() -> Float {
        
        return scaleY
    }
    
    /**
        --Set Space--
        Set the spacing (unscaled; ie. pixel size) to use for the font
     
        - Parameters:
        - space: space for x axis spacing
     */
    func setSpace(space: Float) {
        
        spaceX = space
    }
    
    /**
        --Get Space--
        Get the current spacing used for the font.
     
        - Returns: the x/y space currently used for scale
     */
    func getSpace() -> Float {
        
        return spaceX
    }
    
    /**
        --Get Length of a String--
        Return the length of the specified string if rendered using current settings.
     
        - Parameters:
        - text:    the string to get length for
        - Returns: the length of the specified string (pixels)
     */
    func getLength(text: String) -> Float {
        
        var len: Float = 0.0
        let strLen = text.characters.count
        
        let text1 = text as NSString
        for i in 0..<strLen {
            let c = Int(text1.characterAtIndex(i)) - GLText.CHAR_START
            len += (charWidths[c] * scaleX)
        }
        
        len += (strLen > 1 ? ((Float(strLen) - 1) * spaceX) * scaleX : 0)
        return len
    }
    
    /**
        --Get Width/Height of Character--
        Return the scaled width/height of a character, or max character width.
        NOTE: since all characters are the same height, no character index is required!
        NOTE: excludes spacing!!
     
        - Parameters:
        - chr:     the character to get width for
        - Returns: the requested character size (scaled)
     */
    func getCharWidth(chr: Int) -> Float {
        
        let c = chr - GLText.CHAR_START
        return charWidths[c] * scaleX
    }
    
    func getCharWidthMax() -> Float {
        
        return charWidthMax * scaleX
    }
    
    func getCharHeight() -> Float {
        
        return charHeight * scaleY
    }
    
    /**
        --Get Font Metrics--
        Return the specified (scaled) font metric.
     
        - Returns: the requested font metric (scaled)
     */
    func getAscent() -> Float {
        
        return fontAscent * scaleY
    }
    
    func getDescent() -> Float {
        
        return fontDescent * scaleY
    }
    
    func getHeight() -> Float {
        
        return fontHeight * scaleY
    }
    
    /**
        --Draw Font Texture--
        Draw the entire font texture (NOTE: for testing purposes only).
     
        - Parameters:
        - width, height: the width and height of the area to draw to. this is used
                      to draw the texture to the top-left corner.
        - vpMatrix:      View and projection matrix to use
     */
    func drawTexture(width: Int, _ height: Int, _ vpMatrix: GLKMatrix4) {
        
        initDraw(1.0, 1.0, 1.0, 1.0)
    
        batch!.beginBatch(vpMatrix)
        let idMatrix: GLKMatrix4 = GLKMatrix4Identity
        
        batch!.drawSprite(Float(width - (textureSize / 2)),
                          Float(height - (textureSize / 2)),
                          Float(textureSize), Float(textureSize), textureRgn!, idMatrix)
        batch!.endBatch()
    }
    
    /**
        Cleanup any resources.
     */
    func cleanUp() {
        
        if let texInfo = textureInfo {
            var name = texInfo.name
            glDeleteTextures(1, &name)
        }
        
        if let program = mProgram {
            program.delete()
        }
        
        batch!.cleanUp()
    }
    
    // MARK: Private functions -----------------------------------------------------------
    
    private func initDraw(red: Float, _ green: Float, _ blue: Float, _ alpha: Float) {
        
        glUseProgram(mProgram!.getHandle())
    
        var color: [GLfloat] = [ red, green, blue, alpha ]
        glUniform4fv(mColorHandle, 1, &color)
    
        glActiveTexture(GLenum(GL_TEXTURE0))
        if let texInfo = textureInfo {
            glBindTexture(texInfo.target, texInfo.name)
        }
        glUniform1i(mTextureUniformHandle, 0)
    }
    
    private func drawChar(context: CGContextRef, _ fontRef: CTFontRef, _ char: String,  _ x: CGFloat, _ y: CGFloat) {
        
        var glyph = Array<CGGlyph>(count: 1, repeatedValue: 0)
        var char = [UniChar](char.utf16)
        CTFontGetGlyphsForCharacters(fontRef, &char, &glyph, 1)
        
        var glyphTransform = CGAffineTransformMake(1, 0, 0, -1, x, y)
        
        let path = CTFontCreatePathForGlyph(fontRef, glyph[0], &glyphTransform)
        CGContextAddPath(context, path)
        CGContextFillPath(context)
    }
}
