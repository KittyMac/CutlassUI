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

public struct RenderFrameContext {
    let renderer:Renderer
    let metalLayer:CAMetalLayer
    let pointSize:CGSize
    let pixelSize:CGSize
    let matrix:GLKMatrix4
    let bounds:GLKVector4
    let frameNumber:Int64
}
