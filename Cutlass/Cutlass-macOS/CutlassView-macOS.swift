//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import Cocoa

public class CutlassView: NSView, CALayerDelegate {
    private let _renderer:Renderer
    private let metalLayer:CAMetalLayer
    private let device:MTLDevice!
    private let pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    fileprivate var displayLink: CVDisplayLink?
    
    override init(frame: NSRect) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(coder: aDecoder)
        self.wantsLayer = true
    }
    
    public override func makeBackingLayer() -> CALayer {
        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.delegate = self
        //metalLayer.maximumDrawableCount = Renderer.maxConcurrentFrames
        metalLayer.framebufferOnly = true
        
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleProportionallyToFill
        
        var backgroundColorValues:[CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
                
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        
        return metalLayer
    }
    
    public override func viewDidMoveToWindow() {
        setupCVDisplayLinkForScreen(window!.screen!)
    }
    
    public func renderer() -> Renderer {
        return self._renderer
    }
    
    private func render() {
        autoreleasepool {
            _renderer.render(metalLayer)
        }
    }
    
    func setupCVDisplayLinkForScreen(_ screen:NSScreen) {
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            let view = unsafeBitCast(displayLinkContext, to: CutlassView.self)
            view.render()
            return kCVReturnSuccess
        }
            
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)
    }
    
}
