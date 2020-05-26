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

public struct RenderUnit {
    let shaderType:Int = 0 // TODO: make this an enum
    let cullMode:Int = 0 // TODO: make this an enum
    let textureName:String? = nil
    
    let color:GLKVector4 = GLKVector4Make(1.0, 1.0, 1.0, 1.0)
    
    let renderNumber:Int64
    let vertices:FloatAlignedArray
}
