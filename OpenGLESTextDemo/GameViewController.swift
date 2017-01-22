//
//  GameViewController.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-09-06.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

func BUFFER_OFFSET(_ i: Int) -> UnsafeRawPointer? {
    return UnsafeRawPointer(bitPattern: i)
}

class GameViewController: GLKViewController {
    
    let FONTNAME: [String] = [ "HoeflerText-Regular",
                               "HelveticaNeue-Light",
                               "CourierNewPSMT",
                               "Verdana",
                               "Helvetica" ]
    
    var context: EAGLContext? = nil
    
    var projectionMatrix: GLKMatrix4 = GLKMatrix4Identity
    var viewMatrix: GLKMatrix4 = GLKMatrix4Identity
    var pvMatrix: GLKMatrix4 = GLKMatrix4Identity
    
    var textPVMatrix: GLKMatrix4 = GLKMatrix4Identity
    
    var glTextA: GLText? = nil
    var glTextB: GLText? = nil
    var bgImage: BackgroundImage? = nil
    
    var rotation: Float = 0.0
    
    deinit {
        tearDownGL()
        
        if EAGLContext.current() === context {
            EAGLContext.setCurrent(nil)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("GameViewController - viewDidLoad")
        
        context = EAGLContext(api: .openGLES2)
        
        if !(context != nil) {
            print("Failed to create ES context")
        }
        
        let view = self.view as! GLKView
        view.context = context!
        view.drawableDepthFormat = .format24
        
        setupGL()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
        if isViewLoaded && (view.window != nil) {
            view = nil
            
            tearDownGL()
            
            if EAGLContext.current() === context {
                EAGLContext.setCurrent(nil)
            }
            context = nil
        }
    }
    
    override var prefersStatusBarHidden  : Bool {
        return true
    }
    
    func setupGL() {
        EAGLContext.setCurrent(context)
        
        preferredFramesPerSecond = 60
        
        glClearColor(1.0, 1.0, 1.0, 1.0)
        glEnable(GLenum(GL_BLEND))
        glBlendFunc(GLenum(GL_SRC_ALPHA), GLenum(GL_ONE_MINUS_SRC_ALPHA))
        
        glTextA = GLText()
        let _ = glTextA!.load(FONTNAME[3], 24, 2, 2)
        
        glTextB = GLText()
        let _ = glTextB!.load(FONTNAME[0], 40, 2, 2)
        
        bgImage = BackgroundImage()
        
        let aspect = Float(view.bounds.size.width / view.bounds.size.height)
        
        projectionMatrix = GLKMatrix4MakeOrtho(-aspect, aspect, -1, 1, 3, 7)
        viewMatrix = GLKMatrix4MakeLookAt(0, 0, 3, 0, 0, 0, 0, 1.0, 0.0)
        pvMatrix = GLKMatrix4Multiply(projectionMatrix, viewMatrix)
        
        // Set up a separate projection view for the text
        var projMat: GLKMatrix4 = GLKMatrix4Identity
        var viewMat: GLKMatrix4 = GLKMatrix4Identity
        if view.bounds.size.width > view.bounds.size.height {
            projMat = GLKMatrix4MakeFrustum(-aspect, aspect, -1, 1, 1, 10)
        } else {
            projMat = GLKMatrix4MakeFrustum(-1, 1, -1/aspect, 1/aspect, 1, 10)
        }
        let ext: Float = Float(min(view.bounds.size.width, view.bounds.size.height) / 2)
        viewMat = GLKMatrix4MakeOrtho(-ext, ext, -ext, ext, 0.1, 100)
        textPVMatrix = GLKMatrix4Multiply(projMat, viewMat)
    }
    
    func tearDownGL() {
        EAGLContext.setCurrent(context)
        
        glTextA!.cleanUp()
        glTextB!.cleanUp()
        bgImage!.cleanUp()
    }
    
    // MARK: - GLKView and GLKViewController delegate methods
    
    func update() {
        rotation += Float(timeSinceLastUpdate * 30)
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT) | GLbitfield(GL_DEPTH_BUFFER_BIT))
        
        bgImage!.draw(&pvMatrix)
        
        glTextA!.drawTexture(Int(view.bounds.size.width)/2, Int(view.bounds.size.height)/2, textPVMatrix)
        
        glTextA!.begin(1.0, 1.0, 1.0, 1.0, textPVMatrix)
        glTextA!.draw("Diagonal 1", -40, 40, 40)
        glTextA!.draw("Column 1", -100, 100, 90)
        glTextA!.end()
        
        glTextA!.begin(0.0, 0.0, 1.0, 1.0, textPVMatrix)
        glTextA!.draw("More Lines...", 100, 200)
        glTextA!.draw("The End.", 50, 200 + glTextA!.getCharHeight(), 180)
        glTextA!.end()
        
        glTextB!.begin(0.0, 1.0, 0.0, 1.0, textPVMatrix)
        let _ = glTextB!.drawC("Test String 3D!", 0, 0, 10, 0, -30, 0)
        glTextB!.draw("More Lines...", -100, -200)
        glTextB!.draw("The End.", -150, -200 + glTextB!.getCharHeight(), 180)
        glTextB!.end()
        
        glTextB!.begin(1.0, 0.0, 0.0, 1.0, textPVMatrix)
        let _ = glTextB!.drawC("Rotating Text", -50, -250, 0, 0, 0, rotation)
        glTextB!.end()
    }
}
