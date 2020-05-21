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
                                             _ vertices:FloatAlignedArray) {
        let unit = RenderUnit(renderNumer: 0, vertices: vertices)
        ctx.renderer.submitRenderUnit(ctx, unit)
    }

    
    func protected_viewable_submitRenderFinished(_ ctx:RenderFrameContext) {
        ctx.renderer.submitRenderFinished(ctx)
    }
}

