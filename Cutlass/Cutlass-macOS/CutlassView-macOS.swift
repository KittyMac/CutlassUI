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
    private var contentsScale:CGFloat = 1.0
    private var contentsSize:CGSize = CGSize.zero
    private let pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    fileprivate var displayLink: CVDisplayLink?
    
    override init(frame: NSRect) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(frame: frame)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .topLeft
    }
    
    required init?(coder aDecoder: NSCoder) {
        device = MTLCreateSystemDefaultDevice()!
        _renderer = Renderer(pixelFormat: pixelFormat, device: device)
        metalLayer = CAMetalLayer()
        super.init(coder: aDecoder)
        self.wantsLayer = true
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .topLeft
    }
    
    public override func makeBackingLayer() -> CALayer {
        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.delegate = self
        metalLayer.maximumDrawableCount = 3
        metalLayer.framebufferOnly = true
                
        var backgroundColorValues:[CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
                
        metalLayer.autoresizingMask = CAAutoresizingMask(arrayLiteral: [.layerHeightSizable, .layerWidthSizable])
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.allowsNextDrawableTimeout = false
        
        return metalLayer
    }
    
    public override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        contentsSize = bounds.size
        
        if let window = window {
            if let screen = window.screen {
                contentsScale = screen.backingScaleFactor
                setupCVDisplayLinkForScreen(screen)
            }
        }
    }
    
    public override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize)
        contentsSize = bounds.size
        self.viewDidChangeBackingProperties()
    }
    
    public override func viewDidChangeBackingProperties() {
        guard let window = self.window else { return }
        contentsSize = bounds.size
        metalLayer.contentsScale = window.backingScaleFactor
    }
    
    public func display(_ layer: CALayer) {
        render()
    }
        
    public func renderer() -> Renderer {
        return self._renderer
    }
    
    private func render() {
        autoreleasepool {
            _renderer.render(metalLayer, contentsSize, contentsScale)
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
