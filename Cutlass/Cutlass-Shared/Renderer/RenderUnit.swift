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

public enum ShaderType {
    case abort
    case flat
    case texture
    case sdf
    case stencilBegin
    case stencilEnd
}

public enum CullMode {
    case skip
    case none
    case back
    case front
}

public struct RenderUnit {
    let cullMode:CullMode = .none
    
    let color:GLKVector4 = GLKVector4Make(1.0, 1.0, 1.0, 1.0)
    
    let shaderType:ShaderType
    let renderNumber:Int64
    let vertices:FloatAlignedArray
    let textureName:String?
}
