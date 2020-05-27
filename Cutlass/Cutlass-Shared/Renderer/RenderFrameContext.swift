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

// Immutable state provided to actors.
// RenderFrameContext is immutable state for the entire render frame
// ViewFrameContext is immutable state per view

public struct RenderFrameContext {
    let renderer:Renderer
    let metalLayer:CAMetalLayer
    let pointSize:CGSize
    let pixelSize:CGSize
    let frameNumber:Int64
    let view:ViewFrameContext
    
    func clone(_ view:ViewFrameContext) -> RenderFrameContext {
        return RenderFrameContext(renderer: renderer,
                                  metalLayer: metalLayer,
                                  pointSize: pointSize,
                                  pixelSize: pixelSize,
                                  frameNumber: frameNumber,
                                  view: view)
    }
}

public struct ViewFrameContext {
    let yogaID:YogaID
    let matrix:GLKMatrix4
    let bounds:GLKVector4
    let renderNumber:Int64
    let fitToSize:Bool
    
    init (_ y:YogaID, _ m:GLKMatrix4, _ b:GLKVector4, _ rn:Int64, _ fts:Bool = false) {
        yogaID = y
        matrix = m
        bounds = b
        renderNumber = rn * 100
        fitToSize = fts
    }
    
    init() {
        yogaID = 0
        matrix = GLKMatrix4Identity
        bounds = GLKVector4Make(0.0,0.0,0.0,0.0)
        renderNumber = 0
        fitToSize = false
    }
}
