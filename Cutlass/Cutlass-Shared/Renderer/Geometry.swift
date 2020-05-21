//
//  RenderUnit.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import MetalKit
import GLKit
import simd
import Flynn

public struct Geometry {
    /*
    One unit of geometry. Hash needs to uniquely represent the buffered content in order to allow for reuse of geometric
    data if nothing has changed
    */
    
    var vertices:FloatAlignedArray = FloatAlignedArray()
    
    func invalidate() {
        
    }
}
