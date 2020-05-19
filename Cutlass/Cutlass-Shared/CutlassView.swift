//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

#if os(macOS)
class CutlassView: NSView, CALayerDelegate {
    let renderer:CutlassRenderer
    let metalLayer:CAMetalLayer
    let device:MTLDevice!
    let pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    
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
        metalLayer.maximumDrawableCount = 3
        metalLayer.framebufferOnly = true
        
        self.layerContentsRedrawPolicy = .duringViewResize
        self.layerContentsPlacement = .scaleAxesIndependently
        
        var backgroundColorValues:[CGFloat] = [1, 0, 0, 1]
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
}

#else

class CutlassView: UIView {
    let renderer:CutlassRenderer
    let device:MTLDevice!
    let pixelFormat:MTLPixelFormat = .bgra8Unorm
    
    lazy var metalLayer:CAMetalLayer = self.layer as! CAMetalLayer
    
    override class var layerClass: AnyClass {
        get {
            return CAMetalLayer.self
        }
    }
    
    override init(frame: CGRect) {
        device = MTLCreateSystemDefaultDevice()!
        renderer = CutlassRenderer(pixelFormat: pixelFormat, device: device)
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        device = MTLCreateSystemDefaultDevice()!
        renderer = CutlassRenderer(pixelFormat: pixelFormat, device: device)
        super.init(coder: aDecoder)
    }
    
    override func didMoveToWindow() {
        metalLayer.pixelFormat = pixelFormat
        metalLayer.device = device
        metalLayer.isOpaque = true
        metalLayer.maximumDrawableCount = 3
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self
        
        var backgroundColorValues:[CGFloat] = [1, 0, 0, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
        
        metalLayer.allowsNextDrawableTimeout = false
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
    }
}

#endif
