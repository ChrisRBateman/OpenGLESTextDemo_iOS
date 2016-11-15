//
//  BatchTextProgram.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

class BatchTextProgram : Program {
    
    private let programVariables: [AttribVariable] = [
        AttribVariable.A_Position,
        AttribVariable.A_TexCoordinate,
        AttribVariable.A_MVPMatrixIndex
    ]
    
    private let vertexShaderCode =
        "uniform mat4 u_MVPMatrix[24];      \n"
      + "attribute float a_MVPMatrixIndex;  \n"
      + "attribute vec4 a_Position;         \n"
      + "attribute vec2 a_TexCoordinate;    \n"
      + "varying vec2 v_TexCoordinate;      \n"
      + "void main()                        \n"
      + "{                                  \n"
      + "   int mvpMatrixIndex = int(a_MVPMatrixIndex); \n"
      + "   v_TexCoordinate = a_TexCoordinate;          \n"
      + "   gl_Position = u_MVPMatrix[mvpMatrixIndex]   \n"
      + "               * a_Position;   \n"
      + "}                              \n";
    
    
    private let fragmentShaderCode =
        "uniform sampler2D u_Texture;       \n"
      + "precision mediump float;           \n"
    
      + "uniform vec4 u_Color;              \n"
      + "varying vec2 v_TexCoordinate;      \n"
    
      + "void main()                        \n"
      + "{                                  \n"
      + "   gl_FragColor = texture2D(u_Texture, v_TexCoordinate).w * u_Color;   \n"
      + "}                                  \n";
    
    override func initialize() {
        
        initialize(vertexShaderCode, fragmentShaderCode, programVariables)
    }
}
