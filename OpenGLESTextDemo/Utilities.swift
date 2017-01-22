//
//  Utilities.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

class Utilities {
    
    static func createProgram(_ vertexShaderHandle: GLuint, _ fragmentShaderHandle: GLuint, _ variables: [AttribVariable]) -> GLuint {
        let mProgram = glCreateProgram()
    
        if mProgram != 0 {
            glAttachShader(mProgram, vertexShaderHandle)
            glAttachShader(mProgram, fragmentShaderHandle)
    
            for attVar in variables {
                glBindAttribLocation(mProgram, GLuint(attVar.getHandle()), attVar.getName())
            }
    
            glLinkProgram(mProgram)
            
            var status: GLint = 0
            glGetProgramiv(mProgram, GLenum(GL_LINK_STATUS), &status)
            if status == 0 {
                var logLength: GLint = 0
                glGetProgramiv(mProgram, GLenum(GL_INFO_LOG_LENGTH), &logLength)
                if logLength > 0 {
                    var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
                    glGetProgramInfoLog(mProgram, logLength, &logLength, &log)
                    print("Program link log: ", log)
                }
                
                glDeleteProgram(mProgram)
                return 0
            }
            
            if vertexShaderHandle != 0 {
                glDetachShader(mProgram, vertexShaderHandle)
                glDeleteShader(vertexShaderHandle)
            }
            if fragmentShaderHandle != 0 {
                glDetachShader(mProgram, fragmentShaderHandle)
                glDeleteShader(fragmentShaderHandle)
            }
        }
    
        return mProgram
    }
    
    static func loadShader(_ type: GLenum, _ shaderCode: String) -> GLuint {
        let shaderHandle = glCreateShader(type)
    
        if shaderHandle != 0 {
            var shaderCodeSource = (shaderCode as NSString).utf8String
            glShaderSource(shaderHandle, GLsizei(1), &shaderCodeSource, nil)
            glCompileShader(shaderHandle)
            
            // Get the compilation status.
            var compileStatus: GLint = 0
            glGetShaderiv(shaderHandle, GLenum(GL_COMPILE_STATUS), &compileStatus)
            
            if compileStatus == 0 {
                var logLength: GLint = 0
                glGetShaderiv(shaderHandle, GLenum(GL_INFO_LOG_LENGTH), &logLength)
                if logLength > 0 {
                    var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
                    glGetShaderInfoLog(shaderHandle, logLength, &logLength, &log)
                    print("Shader compile log: ", log)
                }
                
                glDeleteShader(shaderHandle)
                return 0
            }
        }
        
        return shaderHandle
    }
}
