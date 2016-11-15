//
//  Vertices.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit
import OpenGLES

class Vertices {
    
    static let POSITION_CNT_2D = 2
    static let POSITION_CNT_3D = 3
    static let COLOR_CNT = 4
    static let TEXCOORD_CNT = 2
    static let NORMAL_CNT = 3
    static let MVP_MATRIX_INDEX_CNT = 1
    
    private var positionCnt: Int = 0
    private var vertexStride: Int = 0
    private var vertexSize: Int = 0
    
    private var numVertices = 0
    private var numIndices = 0
    
    private var vertices: [Float] = []
    private var indices: [GLushort] = []
    
    private var mTextureCoordinateHandle: Int = 0
    private var mPositionHandle: Int = 0
    private var mMVPIndexHandle: Int = 0
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    var indexBuffer: GLuint = 0
    
    init(_ maxVertices: Int, _ maxIndices: Int) {
        
        positionCnt = Vertices.POSITION_CNT_2D
        vertexStride = positionCnt + Vertices.TEXCOORD_CNT + Vertices.MVP_MATRIX_INDEX_CNT
        vertexSize = vertexStride * 4
        
        vertices = Array<Float>(count: (maxVertices * vertexSize) / sizeof(Float), repeatedValue: 0)
        
        mTextureCoordinateHandle = AttribVariable.A_TexCoordinate.getHandle()
        mPositionHandle = AttribVariable.A_Position.getHandle()
        mMVPIndexHandle = AttribVariable.A_MVPMatrixIndex.getHandle()
    }
    
    /**
        --Set Vertices--
        Set the specified vertices in the vertex buffer.
        NOTE: optimized to use integer buffer!
     
        - Parameters:
        - vertices: array of vertices (floats) to set
        - offset:   offset to first vertex in array
        - length:   number of floats in the vertex array (total)
                    for easy setting use: vtx_cnt * (this.vertexSize / 4)
     */
    func setVertices(vertices: [Float], _ offset: Int, _ length: Int) {
        
        self.vertices.removeAll()
        self.vertices += vertices[offset..<(offset + length)]
        numVertices = length
    }
    
    /**
        --Set Indices--
        Set the specified indices in the index buffer.
     
        - Parameters:
        - indices: array of indices (shorts) to set
        - offset:  offset to first vertex in array
        - length:  number of indices in array (from offset)
                   for easy setting use: vtx_cnt * (this.vertexSize / 4)
     */
    func setIndices(indices: [GLushort], _ offset: Int, _ length: Int) {
        
        self.indices.removeAll()
        self.indices += indices[offset..<(offset + length)]
        numIndices = length
    }
    
    /**
        Set up vertex and index buffer objects.
     */
    func setupData() {
        
        glGenVertexArraysOES(1, &vertexArray)
        glBindVertexArrayOES(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glGenBuffers(1, &indexBuffer)
        
        if vertexBuffer > 0 && indexBuffer > 0 {
            glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
            glBufferData(GLenum(GL_ARRAY_BUFFER), GLsizeiptr(sizeof(GLfloat) * vertices.count), nil,
                         GLenum(GL_DYNAMIC_DRAW))
            
            glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
            glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), GLsizeiptr(sizeof(GLushort) * indices.count), indices,
                         GLenum(GL_STATIC_DRAW))
            
            // bind vertex position pointer
            glVertexAttribPointer(GLuint(mPositionHandle),
                                  GLint(positionCnt), GLenum(GL_FLOAT), 0, GLsizei(vertexSize),
                                  BUFFER_OFFSET(0))
            glEnableVertexAttribArray(GLuint(mPositionHandle))
            
            // bind texture position pointer
            glVertexAttribPointer(GLuint(mTextureCoordinateHandle),
                                  GLint(Vertices.TEXCOORD_CNT), GLenum(GL_FLOAT), 0, GLsizei(vertexSize),
                                  BUFFER_OFFSET(positionCnt * 4))
            glEnableVertexAttribArray(GLuint(mTextureCoordinateHandle))
            
            // bind MVP Matrix index position handle
            glVertexAttribPointer(GLuint(mMVPIndexHandle),
                                  GLint(Vertices.MVP_MATRIX_INDEX_CNT), GLenum(GL_FLOAT), 0, GLsizei(vertexSize),
                                  BUFFER_OFFSET((positionCnt + Vertices.TEXCOORD_CNT) * 4))
            glEnableVertexAttribArray(GLuint(mMVPIndexHandle))
        }
        
        glBindVertexArrayOES(0)
    }
    
    func cleanUp() {
        
        if vertexBuffer > 0 {
            glDeleteBuffers(1, &vertexBuffer)
            vertexBuffer = 0
        }
        
        if indexBuffer > 0 {
            glDeleteBuffers(1, &indexBuffer)
            indexBuffer = 0
        }
        
        if vertexArray != 0 {
            glDeleteVertexArraysOES(1, &vertexArray)
            vertexArray = 0
        }
    }
    
    /**
        --Bind--
        Perform all required binding/state changes before rendering batches.
        USAGE: call once before calling draw() multiple times for this buffer.
     */
    func bind() {
        
        glBindVertexArrayOES(vertexArray)
        
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        // vertices could change every frame so update the gpu memory.
        glBufferSubData(GLenum(GL_ARRAY_BUFFER), 0, GLsizeiptr(sizeof(GLfloat) * numVertices) , vertices)
    }
    
    /**
        --Draw--
        Draw the currently bound vertices in the vertex/index buffers.
        USAGE: can only be called after calling bind() for this buffer.
     
        - Parameters:
        - primitiveType: the type of primitive to draw
        - offset:        the offset in the vertex/index buffer to start at
        - numVertices:   the number of vertices (indices) to draw
     */
    func draw(primitiveType: Int, _ offset: Int, _ numVertices: Int) {
        
        if indices.count > 0 {
            glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
            glDrawElements(GLenum(primitiveType), GLsizei(numVertices), GLenum(GL_UNSIGNED_SHORT), BUFFER_OFFSET(offset))
        } else {
            glDrawArrays(GLenum(primitiveType), GLint(offset), GLsizei(numVertices))
        }
    }
    
    /**
        --Unbind--
        Clear binding states when done rendering batches..
        USAGE: call once after calling draw() multiple times for this buffer.
     */
    func unbind() {
    }
}
