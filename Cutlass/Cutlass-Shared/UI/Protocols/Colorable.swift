//
//  Color.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/20/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Foundation
import Flynn
import GLKit

public class ColorableState {
    var _color:GLKVector4 = GLKVector4Make(1, 1, 1, 1)
    
    var color:Behavior? = nil
    var alpha:Behavior? = nil
        
    init (_ actor:Actor) {
        color = Behavior(actor) { (args:BehaviorArgs) in
            self._color = args[x:0]
        }
        
        alpha = Behavior(actor) { (args:BehaviorArgs) in
            self._color.a = args[x:0]
        }
    }
}

public protocol Colorable : Actor {
    var _colorable:ColorableState { get set }
}

public extension Colorable {
    
    func alpha(_ a:Float) -> Self {
        _colorable.alpha!(a)
        return self
    }
    
    func rgba(_ c:UInt32 ) -> Self {
        let r = Float((c >> 24) & 0xFF) / 255.0
        let g = Float((c >> 16) & 0xFF) / 255.0
        let b = Float((c >> 8) & 0xFF) / 255.0
        let a = Float((c >> 0) & 0xFF) / 255.0
        _colorable.color!(GLKVector4Make(r, g, b, a))
        return self
    }
    
    func rgba(_ r:Float, _ g:Float, _ b:Float, _ a:Float ) -> Self {
        _colorable.color!(GLKVector4Make(r, g, b, a))
        return self
    }
    
    func clear() -> Self {
        _colorable.color!(GLKVector4Make(0, 0, 0, 0))
        return self
    }
    
    func white() -> Self {
        _colorable.color!(GLKVector4Make(1, 1, 1, 1))
        return self
    }
    
    func black() -> Self {
        _colorable.color!(GLKVector4Make(0, 0, 0, 1))
        return self
    }
    
    func gray() -> Self {
        _colorable.color!(GLKVector4Make(0.7, 0.7, 0.7, 1))
        return self
    }
    
    func red() -> Self {
        _colorable.color!(GLKVector4Make(1, 0, 0, 1))
        return self
    }
    
    func green() -> Self {
        _colorable.color!(GLKVector4Make(0, 1, 0, 1))
        return self
    }
    
    func blue() -> Self {
        _colorable.color!(GLKVector4Make(0, 0, 1, 1))
        return self
    }
    
    func yellow() -> Self {
        _colorable.color!(GLKVector4Make(1, 1, 0, 1))
        return self
    }
    
    func magenta() -> Self {
        _colorable.color!(GLKVector4Make(1, 0, 1, 1))
        return self
    }
    
    func cyan() -> Self {
        _colorable.color!(GLKVector4Make(0, 1, 1, 1))
        return self
    }
}

