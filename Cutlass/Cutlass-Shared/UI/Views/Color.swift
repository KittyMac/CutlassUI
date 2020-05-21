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

public final class Color: Actor, Viewable {
    
    private var bufferedGeometry = BufferedGeometry()
    
    public lazy var render = Behavior(self) { (args:BehaviorArgs) in
        let ctx:RenderFrameContext = args[x:0]
        
        // TODO: create and submit the render unit
        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices
        
        vertices.reserve(6 * 7)
        vertices.clear()
        
        vertices.pushQuadVC(GLKVector3Make(0, 0, 0),
                            GLKVector3Make(100, 0, 0),
                            GLKVector3Make(100, 100, 0),
                            GLKVector3Make(0, 100, 0),
                            GLKVector4Make(1.0, 0.0, 0.0, 1.0))
        
        self.protected_viewable_submitRenderUnit(ctx, vertices)
        
        self.protected_viewable_submitRenderFinished(ctx)
    }
}
