//
//  TextureRegion.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

class TextureRegion {
    
    var u1, v1: Float   // Top/Left U,V Coordinates
    var u2, v2: Float   // Bottom/Right U,V Coordinates
    
    /**
        Calculate U,V coordinates from specified texture coordinates.
     
        - Parameters:
        - texWidth, texHeight: the width and height of the texture the region is for
        - x, y:                the top/left (x,y) of the region on the texture (in pixels)
        - width, height:       the width and height of the region on the texture (in pixels)
     */
    init(_ texWidth: Float, _ texHeight: Float, _ x: Float, _ y: Float, _ width: Float, _ height: Float) {
        u1 = x / texWidth
        v1 = y / texHeight
        u2 = u1 + (width / texWidth)
        v2 = v1 + (height / texHeight)
    }
}
