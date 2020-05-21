//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import UIKit
import Flynn

public class CutlassView: UIView {
    let _renderer:Renderer
    let device:MTLDevice!
    let pixelFormat:MTLPixelFormat = .bgra8Unorm
    lazy var metalLayer:CAMetalLayer = self.layer as! CAMetalLayer
    
    fileprivate var displayLink: CADisplayLink?
    
    public override class var layerClass: AnyClass {
        get {
            return CAMetalLayer.self
        }
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
        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.maximumDrawableCount = 3
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self
        
        var backgroundColorValues:[CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
        
        metalLayer.needsDisplayOnBoundsChange = true
        
        if let window = window {
            setupCVDisplayLinkForScreen(window.screen)
        } else {
            displayLink?.invalidate()
            displayLink = nil
            return
        }
        
        displayLink?.add(to: RunLoop.current, forMode: .common)
    }
    
    public func renderer() -> Renderer {
        return self._renderer
    }
    
    @objc func render() {
        autoreleasepool {
            _renderer.render(metalLayer)
        }
    }
    
    func setupCVDisplayLinkForScreen(_ screen:UIScreen) {
        displayLink?.invalidate()
        displayLink = screen.displayLink(withTarget: self, selector: #selector(render))
        displayLink?.preferredFramesPerSecond = 0
    }
}
