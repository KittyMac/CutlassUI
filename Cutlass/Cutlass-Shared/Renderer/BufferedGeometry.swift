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

public struct BufferedGeometry {
    /*
     Memory allocations for large amounts of geometry can get expensive. So the ideal circumstance is we
     allocate it once and it can be used by the native renderer without any copying required. To do this
     and allow multiple frames to be rendered simultaneously (ie the buffer is being used by the renderer
     for the previous frame while we are filling it out for the next frame) we need to have a rotating
     system of buffers.  This class facilitates that.
     */
    var buffers: [Geometry] = []
    var bufferIdx: Int = 0
    let maxBuffers: Int = Renderer.maxConcurrentFrames

    init() {
        for _ in 0..<maxBuffers {
            buffers.append(Geometry())
        }
    }

    mutating func invalidate() {
        for idx in 0..<maxBuffers {
            buffers[idx].invalidate()
        }
    }

    mutating func next() -> Geometry {
        bufferIdx = (bufferIdx + 1) % maxBuffers
        return buffers[bufferIdx]
    }
}
