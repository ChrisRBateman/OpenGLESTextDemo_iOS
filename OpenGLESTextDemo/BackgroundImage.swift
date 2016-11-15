//
//  BackgroundImage.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-27.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

/**
    Renders a background image of stars.
 */
class BackgroundImage: Image {
    
    override init() {
        super.init()
        
        // Setup vertices data for stars.
        verticesData = [
            -1.0, 1.0, 0.0,     // Position 0
            0.0, 0.0,           // TexCoord 0
            
            -1.0, -1.0, 0.0,    // Position 1
            0.0, 1.0,           // TexCoord 1
            
            1.0, -1.0, 0.0,     // Position 2
            1.0, 1.0,           // TexCoord 2
            
            1.0, 1.0, 0.0,      // Position 3
            1.0, 0.0            // TexCoord 3
        ]
        
        textureInfo = loadTexture("graybkgrnd", "png")
        if let texInfo = textureInfo {
            glBindTexture(texInfo.target, texInfo.name)
        }
        
        // Setup data after defining vertices and texture(s).
        setupData()
    }
}
