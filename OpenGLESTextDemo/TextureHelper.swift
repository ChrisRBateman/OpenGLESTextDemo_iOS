//
//  TextureHelper.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

class TextureHelper {
    
    /**
        Load texture from UIImage.
     
        - Parameters:
        - image: UIImage object.
        - Returns: GLKTextureInfo object or nil if error occurs
     */
    static func loadTexture(_ image: UIImage) -> GLKTextureInfo? {
        var textureInfo: GLKTextureInfo? = nil
        do {
            try textureInfo = GLKTextureLoader.texture(with: image.cgImage!, options: [:])
        } catch {
            print("Could not create texture info for image [reason: ", error, "]")
        }
        
        guard let texInfo = textureInfo else { return nil }
        
        return texInfo
    }
}
