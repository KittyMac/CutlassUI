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

func GLKMatrix4EqualToMatrix4(_ aaa: GLKMatrix4, _ bbb: GLKMatrix4) -> Bool {
    return aaa.m00 == bbb.m00 &&
            aaa.m01 == bbb.m01 &&
            aaa.m02 == bbb.m02 &&
            aaa.m03 == bbb.m03 &&
            aaa.m10 == bbb.m10 &&
            aaa.m11 == bbb.m11 &&
            aaa.m12 == bbb.m12 &&
            aaa.m13 == bbb.m13 &&
            aaa.m20 == bbb.m20 &&
            aaa.m21 == bbb.m21 &&
            aaa.m22 == bbb.m22 &&
            aaa.m23 == bbb.m23 &&
            aaa.m30 == bbb.m30 &&
            aaa.m31 == bbb.m31 &&
            aaa.m32 == bbb.m32 &&
            aaa.m33 == bbb.m33
}

public class Geometry {
    /*
    One unit of geometry. Hash needs to uniquely represent the buffered content in order to allow for reuse of geometric
    data if nothing has changed
    */

    var user: Int = 0
    var screen: CGSize = CGSize.zero
    var bounds: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    var matrix: GLKMatrix4 = GLKMatrix4Identity

    var vertices: FloatAlignedArray = FloatAlignedArray()

    func invalidate() {
        user = 0
        screen = CGSize.zero
        bounds = GLKVector4Make(0, 0, 0, 0)
        matrix = GLKMatrix4Identity
    }

    func check(_ ctx: RenderFrameContext, _ matchUser: Int = 0) -> Bool {
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
