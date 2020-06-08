//
//  Color.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/20/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable function_body_length
// swiftlint:disable force_cast

import Foundation
import Flynn
import GLKit

public enum ImageModeType {
    case fill
    case aspectFill
    case aspectFit
    case stretch
}

public class ImageableState<T> {
    var imageHash: Int = 0
    var imageWidth: Int = 0
    var imageHeight: Int = 0
    var imageAspect: Float = 0
    var imageSize: GLKVector2 = GLKVector2Make(0.0, 0.0)

    var path: String?
    var mode: ImageModeType = .fill
    var stretchInsets: GLKVector4 = GLKVector4Make(0, 0, 0, 0)

    lazy var bePath = ChainableBehavior<T> { (args: BehaviorArgs) in
        // flynnlint:parameter String - path to the image
        self.path = args[x:0]
    }

    lazy var beMode = ChainableBehavior<T> { (args: BehaviorArgs) in
        // flynnlint:parameter ImageModeType - image mode for displaying the image
        self.mode = args[x:0]
    }

    lazy var beFill = ChainableBehavior<T> { (_: BehaviorArgs) in
        self.mode = .fill
    }

    lazy var beAspectFill = ChainableBehavior<T> { (_: BehaviorArgs) in
        self.mode = .aspectFill
    }

    lazy var beAspectFit = ChainableBehavior<T> { (_: BehaviorArgs) in
        self.mode = .aspectFit
    }

    lazy var beStretch = ChainableBehavior<T> { (args: BehaviorArgs) in
        // flynnlint:parameter Float - top inset
        // flynnlint:parameter Float - left inset
        // flynnlint:parameter Float - bottom inset
        // flynnlint:parameter Float - right inset
        self.stretchInsets = GLKVector4Make(args[x:0], args[x:1], args[x:2], args[x:3])
        self.mode = .stretch
    }

    lazy var beStretchAll = ChainableBehavior<T> { (args: BehaviorArgs) in
        // flynnlint:parameter Float - top, left, bottom and right inset
        let vvv: Float = args[x:0]
        self.stretchInsets = GLKVector4Make(vvv, vvv, vvv, vvv)
        self.mode = .stretch
    }

    lazy var beUpdateTextureInfo = Behavior { (args: BehaviorArgs) in
        // flynnlint:parameter Renderer - cutlass renderer
        // flynnlint:parameter String - path to image
        // flynnlint:parameter MTLTexture - texture for the image
        let renderer: Renderer = args[x:0]
        let path: String = args[x:1]
        let textureInfo: MTLTexture = args[x:2]
        self.imageWidth = textureInfo.width
        self.imageHeight = textureInfo.height
        self.imageAspect = Float(textureInfo.width) / Float(textureInfo.height)
        self.imageHash = textureInfo.width + textureInfo.height + path.hashValue
        self.imageSize = GLKVector2Make(Float(textureInfo.width), Float(textureInfo.height))
        renderer.beSetNeedsRender()
    }

    init (_ actor: T) {
        bePath.setActor(actor)
        beMode.setActor(actor)
        beFill.setActor(actor)
        beAspectFill.setActor(actor)
        beAspectFit.setActor(actor)
        beStretch.setActor(actor)
        beStretchAll.setActor(actor)
        beUpdateTextureInfo.setActor(actor as! Actor)
    }
}

public protocol Imageable: Actor {
    var safeImageable: ImageableState<Self> { get set }
}

public extension Imageable {

    var bePath: ChainableBehavior<Self> { return safeImageable.bePath }
    var beMode: ChainableBehavior<Self> { return safeImageable.beMode }
    var beFill: ChainableBehavior<Self> { return safeImageable.beFill }
    var beAspectFill: ChainableBehavior<Self> { return safeImageable.beAspectFill }
    var beAspectFit: ChainableBehavior<Self> { return safeImageable.beAspectFit }
    var beStretch: ChainableBehavior<Self> { return safeImageable.beStretch }
    var beStretchAll: ChainableBehavior<Self> { return safeImageable.beStretchAll }
    var beUpdateTextureInfo: Behavior { return safeImageable.beUpdateTextureInfo }

    func safeImageLoaded() -> Bool {
        return (safeImageable.imageWidth != 0) || (safeImageable.imageHeight != 0)
    }

    func safeImageableConfirmImageSize(_ ctx: RenderFrameContext) {
        if let path = safeImageable.path {
            if !safeImageLoaded() {
                ctx.renderer.beGetTextureInfo(path, beUpdateTextureInfo)
            }
        }
    }

    func safeImageableFillVertices(_ ctx: RenderFrameContext,
                                   _ color: GLKVector4,
                                   _ bounds: GLKVector4,
                                   _ vertices: FloatAlignedArray) {
        vertices.reserve(6 * 7)
        vertices.clear()

        if safeImageLoaded() {
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
