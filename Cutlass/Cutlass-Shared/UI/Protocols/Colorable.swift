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
    var color: GLKVector4 = GLKVector4Make(1, 1, 1, 1)

    var beColor: Behavior?
    var beAlpha: Behavior?

    init (_ actor: Actor) {
        beColor = Behavior(actor) { (args: BehaviorArgs) in
            self.color = args[x:0]
        }

        beAlpha = Behavior(actor) { (args: BehaviorArgs) in
            self.color.a = args[x:0]
        }
    }
}

public protocol Colorable: Actor {
    var safeColorable: ColorableState { get set }
}

public extension Colorable {

    func alpha(_ aaa: Float) -> Self {
        safeColorable.beAlpha!(aaa)
        return self
    }

    func rgba(_ ccc: UInt32 ) -> Self {
        let rrr = Float((ccc >> 24) & 0xFF) / 255.0
        let ggg = Float((ccc >> 16) & 0xFF) / 255.0
        let bbb = Float((ccc >> 8) & 0xFF) / 255.0
        let aaa = Float((ccc >> 0) & 0xFF) / 255.0
        safeColorable.beColor!(GLKVector4Make(rrr, ggg, bbb, aaa))
        return self
    }

    func rgba(_ rrr: Float, _ ggg: Float, _ bbb: Float, _ aaa: Float ) -> Self {
        safeColorable.beColor!(GLKVector4Make(rrr, ggg, bbb, aaa))
        return self
    }

    func clear() -> Self {
        safeColorable.beColor!(GLKVector4Make(0, 0, 0, 0))
        return self
    }

    func white() -> Self {
        safeColorable.beColor!(GLKVector4Make(1, 1, 1, 1))
        return self
    }

    func black() -> Self {
        safeColorable.beColor!(GLKVector4Make(0, 0, 0, 1))
        return self
    }

    func gray() -> Self {
        safeColorable.beColor!(GLKVector4Make(0.7, 0.7, 0.7, 1))
        return self
    }

    func red() -> Self {
        safeColorable.beColor!(GLKVector4Make(1, 0, 0, 1))
        return self
    }

    func green() -> Self {
        safeColorable.beColor!(GLKVector4Make(0, 1, 0, 1))
        return self
    }

    func blue() -> Self {
        safeColorable.beColor!(GLKVector4Make(0, 0, 1, 1))
        return self
    }

    func yellow() -> Self {
        safeColorable.beColor!(GLKVector4Make(1, 1, 0, 1))
        return self
    }

    func magenta() -> Self {
        safeColorable.beColor!(GLKVector4Make(1, 0, 1, 1))
        return self
    }

    func cyan() -> Self {
        safeColorable.beColor!(GLKVector4Make(0, 1, 1, 1))
        return self
    }
}
