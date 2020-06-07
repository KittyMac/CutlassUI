//
//  Color.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/20/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable function_body_length

import Foundation
import Flynn
import GLKit

public enum ImageModeType {
    case fill
    case aspectFill
    case aspectFit
    case stretch
}

public class ImageableState {
    var imageHash: Int = 0
    var imageWidth: Int = 0
    var imageHeight: Int = 0
    var imageAspect: Float = 0
    var imageSize: GLKVector2 = GLKVector2Make(0.0, 0.0)

    var path: String?
    var mode: ImageModeType = .fill
    var stretchInsets: GLKVector4 = GLKVector4Make(0, 0, 0, 0)

    var bePath: Behavior?
    var beMode: Behavior?
    var beStretchInsets: Behavior?
    var beUpdateTextureInfo: Behavior?

    init (_ actor: Actor) {
        bePath = Behavior(actor) { (args: BehaviorArgs) in
            self.path = args[x:0]
        }
        beMode = Behavior(actor) { (args: BehaviorArgs) in
            self.mode = args[x:0]
        }
        beStretchInsets = Behavior(actor) { (args: BehaviorArgs) in
            self.stretchInsets = args[x:0]
        }
        beUpdateTextureInfo = Behavior(actor) { (args: BehaviorArgs) in
            let renderer: Renderer = args[x:0]
            let path: String = args[x:1]
            let textureInfo: MTLTexture = args[x:2]
            self.imageWidth = textureInfo.width
            self.imageHeight = textureInfo.height
            self.imageAspect = Float(textureInfo.width) / Float(textureInfo.height)
            self.imageHash = textureInfo.width + textureInfo.height + path.hashValue
            self.imageSize = GLKVector2Make(Float(textureInfo.width), Float(textureInfo.height))
            renderer.setNeedsRender()
        }
    }
}

public protocol Imageable: Actor {
    var safeImageable: ImageableState { get set }
}

public extension Imageable {

    @discardableResult func updateTextureInfo(_ renderer: Renderer, _ path: String, _ texture: MTLTexture) -> Self {
        safeImageable.beUpdateTextureInfo!(renderer, path, texture)
        return self
    }

    @discardableResult func path(_ path: String) -> Self {
        safeImageable.bePath!(path)
        return self
    }

    @discardableResult func stretch(_ top: Float, _ left: Float, _ bottom: Float, _ right: Float) -> Self {
        safeImageable.beStretchInsets!(GLKVector4Make(top, left, bottom, right))
        return self
    }

    @discardableResult func stretchAll(_ vvv: Float) -> Self {
        safeImageable.beStretchInsets!(GLKVector4Make(vvv, vvv, vvv, vvv))
        return self
    }

    @discardableResult func fill() -> Self {
        safeImageable.beMode!(ImageModeType.fill)
        return self
    }
    @discardableResult func aspectFit() -> Self {
        safeImageable.beMode!(ImageModeType.aspectFit)
        return self
    }
    @discardableResult func aspectFill() -> Self {
        safeImageable.beMode!(ImageModeType.aspectFill)
        return self
    }

    func imageLoaded() -> Bool {
        return (safeImageable.imageWidth != 0) || (safeImageable.imageHeight != 0)
    }

    func safeImageable_confirmImageSize(_ ctx: RenderFrameContext) {
        if let path = safeImageable.path {
            if !imageLoaded() {
                ctx.renderer.getTextureInfo(self, path)
            }
        }
    }

    func safeImageable_fillVertices(_ ctx: RenderFrameContext,
                                    _ color: GLKVector4,
                                    _ bounds: GLKVector4,
                                    _ vertices: FloatAlignedArray) {
        vertices.reserve(6 * 7)
        vertices.clear()

        if imageLoaded() {
            let imageAspect = safeImageable.imageAspect
            let boundsAspect = bounds.z / bounds.w

            var xmin = bounds.xMin()
            var ymin = bounds.yMin()
            var xmax = bounds.xMax()
            var ymax = bounds.yMax()

            var smin: Float = 0.0
            var smax: Float = 1.0
            var tmin: Float = 0.0
            var tmax: Float = 1.0

            if safeImageable.mode == .aspectFit {
                if imageAspect > boundsAspect {
                    let ccc = (ymin + ymax) / 2
                    let hhh = (xmax - xmin) / imageAspect
                    ymin = ccc - (hhh / 2)
                    ymax = ccc + (hhh / 2)
                } else {
                    let ccc = (xmin + xmax) / 2
                    let www = (ymax - ymin) * imageAspect
                    xmin = ccc - (www / 2)
                    xmax = ccc + (www / 2)
                }
            } else if safeImageable.mode == .aspectFill {
                let combinedAspect = (imageAspect / boundsAspect)
                if combinedAspect > 1.0 {
                    smin = 0.5 - ((1.0 / combinedAspect) / 2)
                    smax = 0.5 + ((1.0 / combinedAspect) / 2)
                } else {
                    tmin = 0.5 - (combinedAspect / 2)
                    tmax = 0.5 + (combinedAspect / 2)
                }
            }

            vertices.pushQuadVCT(ctx.view.matrix,
                                 GLKVector3Make(xmin, ymin, 0),
                                 GLKVector3Make(xmax, ymin, 0),
                                 GLKVector3Make(xmax, ymax, 0),
                                 GLKVector3Make(xmin, ymax, 0),
                                 color,
                                 GLKVector2Make(smin, tmin),
                                 GLKVector2Make(smax, tmin),
                                 GLKVector2Make(smax, tmax),
                                 GLKVector2Make(smin, tmax))
        }
    }
}
