//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import Cocoa

class CutlassView: NSView, CALayerDelegate {
    let renderer:CutlassRenderer
    let metalLayer:CAMetalLayer
    let device:MTLDevice!
    let pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    fileprivate var displayLink: CVDisplayLink?
    
    override init(frame: NSRect) {
        device = MTLCreateSystemDefaultDevice()!
        renderer = CutlassRenderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(frame: frame)
        self.wantsLayer = true
    }
    
    required init?(coder aDecoder: NSCoder) {
        device = MTLCreateSystemDefaultDevice()!
        renderer = CutlassRenderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(coder: aDecoder)
        self.wantsLayer = true
    }
    
    override func makeBackingLayer() -> CALayer {
        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.delegate = self
        metalLayer.maximumDrawableCount = CutlassRenderer.maxConcurrentFrames
        metalLayer.framebufferOnly = true
        
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        var backgroundColorValues:[CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
        
        metalLayer.allowsNextDrawableTimeout = false
        
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
        
        return metalLayer
    }
    
    override func viewDidMoveToWindow() {
        setupCVDisplayLinkForScreen(window!.screen!)
    }
    
    func render() {
        renderer.render(to: metalLayer)
    }
    
    func setupCVDisplayLinkForScreen(_ screen:NSScreen) -> Bool {
        let displayLinkOutputCallback: CVDisplayLinkOutputCallback = {(displayLink: CVDisplayLink, inNow: UnsafePointer<CVTimeStamp>, inOutputTime: UnsafePointer<CVTimeStamp>, flagsIn: CVOptionFlags, flagsOut: UnsafeMutablePointer<CVOptionFlags>, displayLinkContext: UnsafeMutableRawPointer?) -> CVReturn in
            let view = unsafeBitCast(displayLinkContext, to: CutlassView.self)
            autoreleasepool {
                view.render()
            }
            return kCVReturnSuccess
        }
            
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        CVDisplayLinkSetOutputCallback(displayLink!, displayLinkOutputCallback, UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()))
        CVDisplayLinkStart(displayLink!)

        return true
    }
    
}
