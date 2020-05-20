//
//  File.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import UIKit

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
        metalLayer.maximumDrawableCount = CutlassRenderer.maxConcurrentFrames
        metalLayer.framebufferOnly = true
        metalLayer.delegate = self
        
        var backgroundColorValues:[CGFloat] = [1, 1, 1, 1]
        if let colorSpace = CGColorSpace(name: CGColorSpace.genericRGBLinear) {
            metalLayer.colorspace = colorSpace
            metalLayer.backgroundColor = CGColor(colorSpace: colorSpace, components: &backgroundColorValues)
        }
        
        metalLayer.allowsNextDrawableTimeout = false
        metalLayer.needsDisplayOnBoundsChange = true
        metalLayer.presentsWithTransaction = true
    }
}
