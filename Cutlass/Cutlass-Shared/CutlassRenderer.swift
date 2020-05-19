//
//  CutlassRenderer.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import MetalKit

#if os(iOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

class CutlassRenderer {
    var device: MTLDevice
    
    init(pixelFormat: MTLPixelFormat, device: MTLDevice) {
        self.device = device
    }
}
