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

    public override init() {
        super.init()
        safeViewableInit()
    }

    public lazy var beRender = Behavior(self) { (args: BehaviorArgs) in
        // flynnlint:parameter RenderFrameContext - The render frame context
        let ctx: RenderFrameContext = args[x:0]
        let bounds = ctx.view.bounds

        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices

        self.safeImageableConfirmImageSize(ctx)

        if geom.check(ctx, self.safeImageable.imageHash) == false {
            self.safeImageableFillVertices(ctx,
                                           self.safeColorable.color,
                                           bounds,
                                           vertices)
        }

        self.safeViewableSubmitRenderUnit(ctx,
                                      vertices,
                                      self.safeImageable.imageSize,
                                      .texture,
                                      self.safeImageable.path)

        self.safeViewableSubmitRenderFinished(ctx)
    }
}
