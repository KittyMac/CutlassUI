//
//  Color.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/20/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import Flynn
import GLKit

public protocol Viewable: Actor {
    var render: Behavior { get }
}

public extension Viewable {

    func safeViewable_submitRenderUnit(_ ctx: RenderFrameContext,
                                       _ vertices: FloatAlignedArray,
                                       _ contentSize: GLKVector2,
                                       _ shaderType: ShaderType = .flat,
                                       _ textureName: String? = nil,
                                       _ partNumber: Int64 = 0) {
        let unit = RenderUnit(ctx,
                              shaderType,
                              vertices,
                              contentSize,
                              partNumber,
                              textureName)
        ctx.renderer.submitRenderUnit(ctx, unit)
    }

    func safeViewable_submitRenderFinished(_ ctx: RenderFrameContext) {
        ctx.renderer.submitRenderFinished(ctx)
    }
}
