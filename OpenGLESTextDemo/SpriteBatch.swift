//
//  SpriteBatch.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

class SpriteBatch {
    
    static let VERTEX_SIZE: Int = 5
    static let VERTICES_PER_SPRITE: Int = 4
    static let INDICES_PER_SPRITE: Int = 6
    
    var vertices: Vertices? = nil
    var vertexBuffer: [Float] = []
    var bufferIndex: Int
    var maxSprites: Int
    var numSprites: Int
    fileprivate var mVPMatrix: GLKMatrix4 = GLKMatrix4Identity
    fileprivate var uMVPMatrices: [Float] = Array<Float>(repeating: 0, count: GLText.CHAR_BATCH_SIZE * 16)
    fileprivate var mMVPMatricesHandle: Int32
    var mMVPMatrix: GLKMatrix4 = GLKMatrix4Identity
    
    /**
        Prepare the sprite batcher for specified maximum number of sprites.
     
        - Parameters:
        - maxSprites: the maximum allowed sprites per batch
        - program:    program to use when drawing
     */
    init(_ maxSprites: Int, _ program: Program) {
        vertexBuffer = Array<Float>(repeating: 0, count: maxSprites * SpriteBatch.VERTICES_PER_SPRITE * SpriteBatch.VERTEX_SIZE)
        vertices = Vertices(maxSprites * SpriteBatch.VERTICES_PER_SPRITE, maxSprites * SpriteBatch.INDICES_PER_SPRITE)
        bufferIndex = 0
        self.maxSprites = maxSprites
        numSprites = 0
        
        var indices = Array<GLushort>(repeating: 0, count: maxSprites * SpriteBatch.INDICES_PER_SPRITE)
        let len = indices.count
        var j: GLushort = 0
        for i in stride(from: 0, to: len, by: SpriteBatch.INDICES_PER_SPRITE) {
            indices[i + 0] = (j + 0)           	// Calculate Index 0
            indices[i + 1] = (j + 1)           	// Calculate Index 1
            indices[i + 2] = (j + 2)           	// Calculate Index 2
            indices[i + 3] = (j + 2)           	// Calculate Index 3
            indices[i + 4] = (j + 3)           	// Calculate Index 4
            indices[i + 5] = (j + 0)           	// Calculate Index 5
            j += GLushort(SpriteBatch.VERTICES_PER_SPRITE)
        }
        
        vertices!.setIndices(indices, 0, len);           
        mMVPMatricesHandle = glGetUniformLocation(program.getHandle(), "u_MVPMatrix")
        
        vertices!.setupData()
    }
    
    func cleanUp() {
        vertices!.cleanUp()
    }
    
    func beginBatch(_ vpMatrix: GLKMatrix4) {
        numSprites = 0
        bufferIndex = 0
        mVPMatrix = vpMatrix
    }
    
    /**
        --End Batch--
        Signal the end of a batch. render the batched sprites.
     */
    func endBatch() {
        if numSprites > 0 {
            glUniformMatrix4fv(mMVPMatricesHandle, GLsizei(numSprites), 0, &uMVPMatrices)
            
            vertices!.setVertices(vertexBuffer, 0, bufferIndex)
            vertices!.bind()
            vertices!.draw(Int(GL_TRIANGLES), 0, numSprites * SpriteBatch.INDICES_PER_SPRITE)
            vertices!.unbind()
        }
    }
    
    /**
        --Draw Sprite to Batch--
        Batch specified sprite to batch. adds vertices for sprite to vertex buffer.
        NOTE: MUST be called after beginBatch(), and before endBatch()!
        NOTE: if the batch overflows, this will render the current batch, restart it,
           and then batch this sprite.
     
        - Parameters:
        - x, y:          the x,y position of the sprite (center)
        - width, height: the width and height of the sprite
        - region:        the texture region to use for sprite
        - modelMatrix:   the model matrix to assign to the sprite
     */
    func drawSprite(_ x: Float, _ y: Float, _ width: Float, _ height: Float, _ region: TextureRegion, _ modelMatrix: GLKMatrix4) {
        if numSprites == maxSprites {
            endBatch()
            numSprites = 0
            bufferIndex = 0
        }
        
        let halfWidth = width / 2.0
        let halfHeight = height / 2.0
        let x1 = x - halfWidth
        let y1 = y - halfHeight
        let x2 = x + halfWidth
        let y2 = y + halfHeight
        
        vertexBuffer[bufferIndex] = x1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = y1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.u1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.v2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = Float(numSprites)
        bufferIndex += 1
        
        vertexBuffer[bufferIndex] = x2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = y1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.u2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.v2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = Float(numSprites)
        bufferIndex += 1
        
        vertexBuffer[bufferIndex] = x2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = y2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.u2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.v1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = Float(numSprites)
        bufferIndex += 1
        
        vertexBuffer[bufferIndex] = x1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = y2
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.u1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = region.v1
        bufferIndex += 1
        vertexBuffer[bufferIndex] = Float(numSprites)
        bufferIndex += 1
        
        mMVPMatrix = GLKMatrix4Multiply(mVPMatrix, modelMatrix)
        
        //TODO: make sure numSprites < 24
        for i in 0..<16 {
            uMVPMatrices[numSprites * 16 + i] = mMVPMatrix[i]
        }
        
        numSprites += 1
    }
}
