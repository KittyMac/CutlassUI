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
/*
public class EventableState {
    var eventInsets: GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    var eventInset: Behavior?

    init (_ actor: Actor) {
        eventInset = Behavior(actor) { (args: BehaviorArgs) in
            self.eventInsets = args[x:0]
        }
    }
}

public protocol Eventable: Actor {
    var safeEventable: EventableState { get set }
}

public extension Eventable {

    func safeEventable_transformPoint(_ ctx: RenderFrameContext, _ point: GLKVector2) -> GLKVector2 {
        // convert point from local coordinates to global coordinates
        let ppp = GLKMatrix4MultiplyVector3WithTranslation(ctx.view.matrix, GLKVector3Make(point.x, point.y, 0))
        return GLKVector2Make(ppp.x, ppp.y)
    }

    func safeEventable_inverseTransformPoint(_ ctx: RenderFrameContext, _ point: GLKVector2) -> GLKVector2 {
        // convert point from global coordinates to local coordinates
        //match M4fun.inv(frameContext.matrix)
        //| let inv_matrix:M4 =>
        //  V3fun.v2(M4fun.mul_v3_point_3x4(inv_matrix, V3fun(point._1, point._2, 0.0)))
        //else
        //  @printf[U32]("WARNING: unable to invert matrix in inverseTransformPoint".cstring())
        //  point
        //end
        return GLKVector2Make(0.0, 0.0)
    }

    func safeEventable_pointInBounds(_ ctx: RenderFrameContext,
                                     _ bounds: GLKVector4,
                                     _ point: GLKVector2) -> Bool {
        // convert point from global coordinates to local coordinates
        //R4fun.contains(bounds, inverseTransformPoint(frameContext, point) )
        return false
    }

    func safeEventInset(_ top: Pixel, _ left: Pixel, _ bottom: Pixel, _ right: Pixel) -> Self {
        safeEventable.eventInset!(GLKVector4Make(top, left, bottom, right))
        return self
    }

    func safeEventInsetAll(_ inset: Pixel) -> Self {
        safeEventable.eventInset!(GLKVector4Make(inset, inset, inset, inset))
        return self
    }
}
*/
