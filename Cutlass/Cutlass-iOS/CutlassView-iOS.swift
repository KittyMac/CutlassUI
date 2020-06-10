//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

// swiftlint:disable force_cast

import Foundation
import UIKit
import Flynn

public class CutlassView: UIView {
    private let _renderer: Renderer
    private let device: MTLDevice!
    private let pixelFormat: MTLPixelFormat = .bgra8Unorm
    private var contentsScale: CGFloat = 1.0
    private var contentsSize: CGSize = CGSize.zero
    private lazy var metalLayer: CAMetalLayer = self.layer as! CAMetalLayer

    fileprivate var displayLink: CADisplayLink?

    public override class var layerClass: AnyClass {
        return CAMetalLayer.self
    }

    override init(frame: CGRect) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        super.init(coder: aDecoder)
    }

    public override func didMoveToWindow() {

        super.didMoveToWindow()

        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.maximumDrawableCount = 3
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self

        var backgroundColorValues: [CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }

        metalLayer.needsDisplayOnBoundsChange = true

        contentsSize = bounds.size

        if let window = window {
            contentsScale = window.screen.nativeScale
            setupCVDisplayLinkForScreen(window.screen)
        } else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }

        displayLink?.add(to: RunLoop.current, forMode: .common)
    }

    public override func layoutSubviews() {
        contentsSize = bounds.size
    }

    override public func display(_ layer: CALayer) {
        render()
    }

    public func renderer() -> Renderer {
        return self._renderer
    }

    @objc func render() {
        autoreleasepool {
            contentsSize = bounds.size
            _renderer.beRenderFrame(metalLayer, contentsSize, contentsScale)
        }
    }

    func setupCVDisplayLinkForScreen(_ screen: UIScreen) {
        displayLink?.invalidate()
        displayLink = screen.displayLink(withTarget: self, selector: #selector(render))
        displayLink?.preferredFramesPerSecond = 0
    }
}
