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
    func protected_viewableRender(_ args:BehaviorArgs) {
        print("Viewable.render()")
    }
    
    func protected_viewableRenderFinished(_ ctx:RenderFrameContext) {
        ctx.renderer.submitRenderFinished(ctx)
    }
}

