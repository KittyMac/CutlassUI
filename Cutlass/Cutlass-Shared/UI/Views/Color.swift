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
    public lazy var safeColorable = ColorableState(self)

    private var bufferedGeometry = BufferedGeometry()

    public lazy var render = Behavior(self) { (args: BehaviorArgs) in
        let ctx: RenderFrameContext = args[x:0]
        let bounds = ctx.view.bounds

        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices

        if geom.check(ctx) == false {
            vertices.reserve(6 * 7)
            vertices.clear()

            let xmin = bounds.xMin()
            let ymin = bounds.yMin()
            let xmax = bounds.xMax()
            let ymax = bounds.yMax()

            vertices.pushQuadVC(ctx.view.matrix,
                                GLKVector3Make(xmin, ymin, 0),
                                GLKVector3Make(xmax, ymin, 0),
                                GLKVector3Make(xmax, ymax, 0),
                                GLKVector3Make(xmin, ymax, 0),
                                self.safeColorable.color)
        }

        self.safeViewable_submitRenderUnit(ctx, vertices, bounds.size())

        self.safeViewable_submitRenderFinished(ctx)
    }
}
