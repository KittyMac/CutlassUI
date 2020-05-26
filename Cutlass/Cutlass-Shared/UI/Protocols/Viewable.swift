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

public protocol Viewable : Actor {
    var render:Behavior { get }
}

public extension Viewable {
    
    func protected_viewable_submitRenderUnit(_ ctx:RenderFrameContext,
                                             _ vertices:FloatAlignedArray,
                                             _ shaderType: ShaderType = .flat,
                                             _ partNumber:Int64 = 0) {
        let unit = RenderUnit(shaderType: shaderType, renderNumber: ctx.view.renderNumber + partNumber, vertices: vertices)
        ctx.renderer.submitRenderUnit(ctx, unit)
    }

    
    func protected_viewable_submitRenderFinished(_ ctx:RenderFrameContext) {
        ctx.renderer.submitRenderFinished(ctx)
    }
}

