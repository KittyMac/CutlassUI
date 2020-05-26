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

public final class Color: Actor, Viewable, Colorable {
    public lazy var _colorable = ColorableState(self)
    
    private var bufferedGeometry = BufferedGeometry()
    
    public lazy var render = Behavior(self) { (args:BehaviorArgs) in
        let ctx:RenderFrameContext = args[x:0]
        let bounds = ctx.view.bounds
        
        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices
        
        vertices.reserve(6 * 7)
        vertices.clear()
        
        let x_min = bounds.xMin()
        let y_min = bounds.yMin()
        let x_max = bounds.xMax()
        let y_max = bounds.yMax()

        vertices.pushQuadVC(ctx.view.matrix,
                            GLKVector3Make(x_min, y_min, 0),
                            GLKVector3Make(x_max, y_min, 0),
                            GLKVector3Make(x_max, y_max, 0),
                            GLKVector3Make(x_min, y_max, 0),
                            self._colorable._color)
        
        self.protected_viewable_submitRenderUnit(ctx, vertices)
        
        self.protected_viewable_submitRenderFinished(ctx)
    }
}
