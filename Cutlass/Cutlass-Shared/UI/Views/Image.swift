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

public final class Image: Actor, Viewable, Colorable, Imageable {
    public lazy var safeColorable = ColorableState(self)
    public lazy var safeImageable = ImageableState(self)

    private var bufferedGeometry = BufferedGeometry()

    public lazy var render = Behavior(self) { (args: BehaviorArgs) in
        let ctx: RenderFrameContext = args[x:0]
        let bounds = ctx.view.bounds

        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices

        self.safeImageable_confirmImageSize(ctx)

        if geom.check(ctx, self.safeImageable.imageHash) == false {
            self.safeImageable_fillVertices(ctx,
                                                  self.safeColorable.color,
                                                  bounds,
                                                  vertices)
        }

        self.safeViewable_submitRenderUnit(ctx,
                                                 vertices,
                                                 self.safeImageable.imageSize,
                                                 .texture,
                                                 self.safeImageable.path)

        self.safeViewable_submitRenderFinished(ctx)
    }
}
