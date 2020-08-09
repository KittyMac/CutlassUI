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
}

public protocol Imageable: Actor, UpdateTextureInfo {
    var safeImageable: ImageableState { get set }
}

public extension Imageable {

    private func _bePath(_ path: String) {
        safeImageable.path = path
    }

    private func _beMode(_ mode: ImageModeType) {
        safeImageable.mode = mode
    }

    private func _beFill() {
        safeImageable.mode = .fill
    }

    private func _beAspectFill() {
        safeImageable.mode = .aspectFill
    }

    private func _beAspectFit() {
        safeImageable.mode = .aspectFit
    }

    private func _beStretch(_ top: Float,
                            _ left: Float,
                            _ bottom: Float,
                            _ right: Float) {
        safeImageable.stretchInsets = GLKVector4Make(top, left, bottom, right)
        safeImageable.mode = .stretch
    }

    private func _beStretchAll(_ value: Float) {
        // flynnlint:parameter Float - top, left, bottom and right inset
        safeImageable.stretchInsets = GLKVector4Make(value, value, value, value)
        safeImageable.mode = .stretch
    }

    private func _beUpdateTextureInfo(_ renderer: Renderer,
                                      _ path: String,
                                      _ textureInfo: MTLTexture) {
        safeImageable.imageWidth = textureInfo.width
        safeImageable.imageHeight = textureInfo.height
        safeImageable.imageAspect = Float(textureInfo.width) / Float(textureInfo.height)
        safeImageable.imageHash = textureInfo.width + textureInfo.height + path.hashValue
        safeImageable.imageSize = GLKVector2Make(Float(textureInfo.width), Float(textureInfo.height))
        renderer.beSetNeedsRender()
    }

    func safeImageLoaded() -> Bool {
        return (safeImageable.imageWidth != 0) || (safeImageable.imageHeight != 0)
    }

    func safeImageableConfirmImageSize(_ ctx: RenderFrameContext) {
        if let path = safeImageable.path {
            if !safeImageLoaded() {
                ctx.renderer.beGetTextureInfo(path, self)
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

// MARK: - Autogenerated by FlynnLint
// Contents of file after this marker will be overwritten as needed

extension Imageable {

    @discardableResult
    public func bePath(_ path: String) -> Self {
        unsafeSend { self._bePath(path) }
        return self
    }
    @discardableResult
    public func beMode(_ mode: ImageModeType) -> Self {
        unsafeSend { self._beMode(mode) }
        return self
    }
    @discardableResult
    public func beFill() -> Self {
        unsafeSend(_beFill)
        return self
    }
    @discardableResult
    public func beAspectFill() -> Self {
        unsafeSend(_beAspectFill)
        return self
    }
    @discardableResult
    public func beAspectFit() -> Self {
        unsafeSend(_beAspectFit)
        return self
    }
    @discardableResult
    public func beStretch(_ top: Float, _ left: Float, _ bottom: Float, _ right: Float) -> Self {
        unsafeSend { self._beStretch(top, left, bottom, right) }
        return self
    }
    @discardableResult
    public func beStretchAll(_ value: Float) -> Self {
        unsafeSend { self._beStretchAll(value) }
        return self
    }
    @discardableResult
    public func beUpdateTextureInfo(_ renderer: Renderer, _ path: String, _ textureInfo: MTLTexture) -> Self {
        unsafeSend { self._beUpdateTextureInfo(renderer, path, textureInfo) }
        return self
    }

}
