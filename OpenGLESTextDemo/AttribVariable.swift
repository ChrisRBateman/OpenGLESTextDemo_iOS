//
//  AttribVariable.swift
//  OpenGLESTextDemo
//
//  Created by Chris Bateman on 2016-10-20.
//  Copyright © 2016 Chris Bateman. All rights reserved.
//

import GLKit

struct AttribVariable {
    
    static let A_Position = AttribVariable(1, "a_Position")
    static let A_TexCoordinate = AttribVariable(2, "a_TexCoordinate")
    static let A_MVPMatrixIndex = AttribVariable(3, "a_MVPMatrixIndex")
    
    fileprivate var mHandle: Int
    fileprivate var mName: String
    
    init(_ handle: Int, _ name: String) {
        mHandle = handle
        mName = name
    }
    
    func getHandle() -> Int {
        return mHandle
    }
    
    func getName() -> String {
        return mName
    }
}
