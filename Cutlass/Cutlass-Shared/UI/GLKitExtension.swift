//
//  Yoga.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import Cutlass.Yoga
import GLKit
import Flynn

extension GLKVector4 {
    func xMin() -> Float {
        return x
    }
    
    func xMax() -> Float {
        return x + z
    }
    
    func yMin() -> Float {
        return y
    }
    
    func yMax() -> Float {
        return y + w
    }
    
    func width() -> Float {
        return z
    }
    
    func height() -> Float {
        return w
    }
    
    func size() -> GLKVector2 {
        return GLKVector2Make(z, w)
    }
}
