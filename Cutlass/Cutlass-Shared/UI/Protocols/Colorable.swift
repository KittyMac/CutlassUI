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
    var _color:GLKVector4 = GLKVector4Make(0, 0, 0, 0)
    
    var color:Behavior? = nil
        
    init (_ actor:Actor) {
        color = Behavior(actor) { (args:BehaviorArgs) in
            self._color = args[x:0]
        }
    }
}

public protocol Colorable : Actor {
    var _colorable:ColorableState { get set }
}

public extension Colorable {
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

