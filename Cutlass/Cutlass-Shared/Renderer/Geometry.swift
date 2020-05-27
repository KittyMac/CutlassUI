//
//  RenderUnit.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import MetalKit
import GLKit
import simd
import Flynn

func GLKMatrix4EqualToMatrix4(_ a:GLKMatrix4, _ b:GLKMatrix4) -> Bool {
    return a.m00 == b.m00 &&
            a.m01 == b.m01 &&
            a.m02 == b.m02 &&
            a.m03 == b.m03 &&
            a.m10 == b.m10 &&
            a.m11 == b.m11 &&
            a.m12 == b.m12 &&
            a.m13 == b.m13 &&
            a.m20 == b.m20 &&
            a.m21 == b.m21 &&
            a.m22 == b.m22 &&
            a.m23 == b.m23 &&
            a.m30 == b.m30 &&
            a.m31 == b.m31 &&
            a.m32 == b.m32 &&
            a.m33 == b.m33
}

public class Geometry {
    /*
    One unit of geometry. Hash needs to uniquely represent the buffered content in order to allow for reuse of geometric
    data if nothing has changed
    */
    
    var user:Int = 0
    var screen:CGSize = CGSize.zero
    var bounds:GLKVector4 = GLKVector4Make(0,0,0,0)
    var matrix:GLKMatrix4 = GLKMatrix4Identity
    
    var vertices:FloatAlignedArray = FloatAlignedArray()
    
    func invalidate() {
        user = 0
        screen = CGSize.zero
        bounds = GLKVector4Make(0,0,0,0)
        matrix = GLKMatrix4Identity
    }
    
    func check(_ ctx:RenderFrameContext, _ matchUser:Int = 0) -> Bool {
        if  user == matchUser &&
            screen.width == ctx.pixelSize.width && screen.height == ctx.pixelSize.height &&
            GLKVector4AllEqualToVector4(bounds, ctx.view.bounds) &&
            GLKMatrix4EqualToMatrix4(matrix, ctx.view.matrix) {
            return true
        }
        
        user = matchUser
        screen = ctx.pixelSize
        bounds = ctx.view.bounds
        matrix = ctx.view.matrix
        
        return false
    }
}
