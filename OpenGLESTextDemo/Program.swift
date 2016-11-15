//
//  Program.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

class Program {
    
    private var programHandle: GLuint = 0
    private var vertexShaderHandle: GLuint = 0
    private var fragmentShaderHandle: GLuint = 0
    private var mInitialized: Bool
 
    init() {
        
        mInitialized = false
    }
    
    func initialize() {
        
        initialize(nil, nil, nil)
    }
    
    func initialize(vertexShaderCode: String?,
                    _ fragmentShaderCode: String?,
                    _ programVariables: [AttribVariable]?) {
        
		vertexShaderHandle = Utilities.loadShader(GLenum(GL_VERTEX_SHADER), vertexShaderCode!)
		fragmentShaderHandle = Utilities.loadShader(GLenum(GL_FRAGMENT_SHADER), fragmentShaderCode!)
		
		programHandle = Utilities.createProgram(vertexShaderHandle, fragmentShaderHandle, programVariables!)
		
        mInitialized = true
	}
    
    func getHandle() -> GLuint {
        
        return programHandle
    }
    
    func delete() {
        
        glDeleteShader(vertexShaderHandle)
        glDeleteShader(fragmentShaderHandle)
        glDeleteProgram(programHandle)
        mInitialized = false
    }
    
    func initialized() -> Bool {
        
        return mInitialized
    }
}
