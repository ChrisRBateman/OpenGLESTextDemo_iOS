//
//  Image.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-06.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

/**
    Base class for all images.
 */
class Image {
    
    var textureInfo: GLKTextureInfo? = nil
    var program: GLuint = 0
    
    var samplerLocation: GLint = 0
    var mvpMatrixLocation: GLint = 0
    
    var verticesData: [GLfloat] = []
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    var indexBuffer: GLuint = 0
    
    init() {
    }
    
    /**
        Setup resources.
     */
    func setupData() {
        let vertexShaderCode =
            "uniform mat4 uMVPMatrix;" +
                "attribute vec4 aPosition;" +
                "attribute vec2 aTexCoord;" +
                "varying vec2 vTexCoord;" +
                "void main() {" +
                "    gl_Position = uMVPMatrix * aPosition;" +
                "    vTexCoord = aTexCoord;" +
        "}"
        
        let fragmentShaderCode =
            "precision mediump float;" +
                "varying vec2 vTexCoord;" +
                "uniform sampler2D sTexture;" +
                "void main() {" +
                "    gl_FragColor = texture2D(sTexture, vTexCoord);" +
        "}"
        
        // Create program from shaders
        program = loadProgram(vertexShaderCode, fragmentShaderCode)
        
        // Get locations
        samplerLocation = glGetUniformLocation(program, "sTexture")
        mvpMatrixLocation = glGetUniformLocation(program, "uMVPMatrix")
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLfloat>.size * verticesData.count), &verticesData, GLenum(GL_STATIC_DRAW))
        
        let indicesData: [GLushort] = [ 0, 1, 2, 0, 2, 3 ]
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), GLsizeiptr(MemoryLayout<GLushort>.size * indicesData.count), indicesData, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.position.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.position.rawValue), 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(0))
        glEnableVertexAttribArray(GLuint(GLKVertexAttrib.texCoord0.rawValue))
        glVertexAttribPointer(GLuint(GLKVertexAttrib.texCoord0.rawValue), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 20, BUFFER_OFFSET(12))
        
        glBindVertexArrayOES(0)
    }
    
    /**
        Draws an image using mvpMatrix to position image.
     
        - Parameters:
        - mvpMatrix: the Model View Projection matrix to position image
     */
    func draw(_ mvpMatrix: inout GLKMatrix4) {
        glBindVertexArrayOES(vertexArray)
        
        glUseProgram(program)
        
        if let texInfo = textureInfo {
            glActiveTexture(GLenum(GL_TEXTURE0))
            glBindTexture(texInfo.target, texInfo.name)
            glUniform1i(samplerLocation, 0)
        }
        
        withUnsafePointer(to: &mvpMatrix, {
            $0.withMemoryRebound(to: Float.self, capacity: 16, {
                glUniformMatrix4fv(mvpMatrixLocation, 1, 0, $0)
            })
        })
        
        glDrawElements(GLenum(GL_TRIANGLES), 6, GLenum(GL_UNSIGNED_SHORT), BUFFER_OFFSET(0))
    }
    
    /**
        Cleanup any resources.
     */
    func cleanUp() {
        if let texInfo = textureInfo {
            var name = texInfo.name
            glDeleteTextures(1, &name)
        }
        
        if vertexBuffer != 0 {
            glDeleteBuffers(1, &vertexBuffer)
            vertexBuffer = 0
        }
        
        if indexBuffer != 0 {
            glDeleteBuffers(1, &indexBuffer)
            indexBuffer = 0
        }
        
        if vertexArray != 0 {
            glDeleteVertexArraysOES(1, &vertexArray)
            vertexArray = 0
        }
        
        if program != 0 {
            glDeleteProgram(program)
            program = 0
        }
    }
    
    /**
        Load texture from file (of type). File should be part of project.
     
        - Parameters:
        - file: Name of texture file.
        - type: Type of texture file.
        - Returns: GLKTextureInfo object or nil if error occurs
     */
    func loadTexture(_ file: String, _ type: String) -> GLKTextureInfo? {
        let imagePathname = Bundle.main.path(forResource: file, ofType: type)!
        
        var textureInfo: GLKTextureInfo? = nil
        do {
            try textureInfo = GLKTextureLoader.texture(withContentsOfFile: imagePathname, options: [:])
        } catch {
            print("Could not create texture info for image [reason: ", error, "]")
        }
        
        guard let texInfo = textureInfo else { return nil }
        
        return texInfo
    }
    
    /**
        Load texture from UIImage.
     
        - Parameters:
        - image: UIImage object.
        - Returns: GLKTextureInfo object or nil if error occurs
     */
    func loadTexture(_ image: UIImage) -> GLKTextureInfo? {
        var textureInfo: GLKTextureInfo? = nil
        do {
            try textureInfo = GLKTextureLoader.texture(with: image.cgImage!, options: [:])
        } catch {
            print("Could not create texture info for image [reason: ", error, "]")
        }
        
        guard let texInfo = textureInfo else { return nil }
        
        return texInfo
    }
    
    /**
     Load texture from NSData.
     
     - Parameters:
     - data: NSData object.
     - Returns: GLKTextureInfo object or nil if error occurs
     */
    func loadTexture(_ data: Data) -> GLKTextureInfo? {
        var textureInfo: GLKTextureInfo? = nil
        do {
            try textureInfo = GLKTextureLoader.texture(withContentsOf: data, options: [:])
        } catch {
            print("Could not create texture info for data [reason: ", error, "]")
        }
        
        guard let texInfo = textureInfo else { return nil }
        
        return texInfo
    }
    
    func validateProgram(_ prog: GLuint) -> Bool {
        var logLength: GLsizei = 0
        var status: GLint = 0
        
        glValidateProgram(prog)
        glGetProgramiv(prog, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(prog, logLength, &logLength, &log)
            print("Program validate log: \n\(log)")
        }
        
        glGetProgramiv(prog, GLenum(GL_VALIDATE_STATUS), &status)
        var returnVal = true
        if status == 0 {
            returnVal = false
        }
        return returnVal
    }
    
    /**
        Loads vertex and fragment shaders, creates program object, links program, returns
        program id.
     
        - Parameters:
        - vShaderCode: Vertex shader code as string.
        - fShaderCode: Fragment shader as string.
        - Returns: Program id of created program or 0 if error occurs.
     */
    func loadProgram(_ vShaderCode: String, _ fShaderCode: String) -> GLuint {
        var program: GLuint = 0
        var vertShader: GLuint = 0
        var fragShader: GLuint = 0
        var status: GLint = 0
        
        vertShader = loadShader(GLenum(GL_VERTEX_SHADER), vShaderCode)
        if vertShader == 0 {
            return 0
        }
        
        fragShader = loadShader(GLenum(GL_FRAGMENT_SHADER), fShaderCode)
        if fragShader == 0 {
            glDeleteShader(vertShader)
            return 0
        }
        
        program = glCreateProgram()
        if program == 0 {
            glDeleteShader(vertShader)
            glDeleteShader(fragShader)
            return 0
        }
        
        glAttachShader(program, vertShader)
        glAttachShader(program, fragShader)
        
        // Bind attribute locations.
        // This needs to be done prior to linking.
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.position.rawValue), "aPosition")
        glBindAttribLocation(program, GLuint(GLKVertexAttrib.texCoord0.rawValue), "aTexCoord")
        
        glLinkProgram(program)
        
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == 0 {
            var logLength: GLint = 0
            glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
                glGetProgramInfoLog(program, logLength, &logLength, &log)
                print("Program link log: ", log)
            }
            
            glDeleteProgram(program)
            return 0
        }
        
        if vertShader != 0 {
            glDetachShader(program, vertShader)
            glDeleteShader(vertShader)
        }
        if fragShader != 0 {
            glDetachShader(program, fragShader)
            glDeleteShader(fragShader)
        }
        
        return program
    }
    
    /**
        Create, load and compile a shader of type.
     
        - Parameters:
        - type: The type of shader.
        - shaderCode: The shader code.
        - Returns: Shader id of created shader or 0 if error occurs.
     */
    func loadShader(_ type: GLenum, _ shaderCode: String) -> GLuint {
        var shader: GLuint = 0
        var status: GLint = 0
        
        shader = glCreateShader(type)
        if shader == 0 {
            return 0
        }
        
        var shaderCodeSource = (shaderCode as NSString).utf8String
        glShaderSource(shader, GLsizei(1), &shaderCodeSource, nil)
        glCompileShader(shader)
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        
        if status == 0 {
            var logLength: GLint = 0
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &logLength)
            if logLength > 0 {
                var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
                glGetShaderInfoLog(shader, logLength, &logLength, &log)
                print("Shader compile log: ", log)
            }
            
            glDeleteShader(shader)
            return 0
        }
        
        return shader
    }
}

