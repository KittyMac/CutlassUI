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
    var protected_colorable:ColorableState { get set }
}

public extension Colorable {
    
    func alpha(_ a:Float) -> Self {
        protected_colorable.alpha!(a)
        return self
    }
    
    func rgba(_ c:UInt32 ) -> Self {
        let r = Float((c >> 24) & 0xFF) / 255.0
        let g = Float((c >> 16) & 0xFF) / 255.0
        let b = Float((c >> 8) & 0xFF) / 255.0
        let a = Float((c >> 0) & 0xFF) / 255.0
        protected_colorable.color!(GLKVector4Make(r, g, b, a))
        return self
    }
    
    func rgba(_ r:Float, _ g:Float, _ b:Float, _ a:Float ) -> Self {
        protected_colorable.color!(GLKVector4Make(r, g, b, a))
        return self
    }
    
    func clear() -> Self {
        protected_colorable.color!(GLKVector4Make(0, 0, 0, 0))
        return self
    }
    
    func white() -> Self {
        protected_colorable.color!(GLKVector4Make(1, 1, 1, 1))
        return self
    }
    
    func black() -> Self {
        protected_colorable.color!(GLKVector4Make(0, 0, 0, 1))
        return self
    }
    
    func gray() -> Self {
        protected_colorable.color!(GLKVector4Make(0.7, 0.7, 0.7, 1))
        return self
    }
    
    func red() -> Self {
        protected_colorable.color!(GLKVector4Make(1, 0, 0, 1))
        return self
    }
    
    func green() -> Self {
        protected_colorable.color!(GLKVector4Make(0, 1, 0, 1))
        return self
    }
    
    func blue() -> Self {
        protected_colorable.color!(GLKVector4Make(0, 0, 1, 1))
        return self
    }
    
    func yellow() -> Self {
        protected_colorable.color!(GLKVector4Make(1, 1, 0, 1))
        return self
    }
    
    func magenta() -> Self {
        protected_colorable.color!(GLKVector4Make(1, 0, 1, 1))
        return self
    }
    
    func cyan() -> Self {
        protected_colorable.color!(GLKVector4Make(0, 1, 1, 1))
        return self
    }
}

