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

public class ColorableState<T: Actor> {
    public var color: GLKVector4 = GLKVector4Make(1, 1, 1, 1)

    private func setColor(_ red: Float, _ green: Float, _ blue: Float, _ alpha: Float) {
        color = GLKVector4Make(red, green, blue, alpha)
    }

    lazy var beColor = ChainableBehavior<T> { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter NSNumber - red component
        // flynnlint:parameter NSNumber - green component
        // flynnlint:parameter NSNumber - blue component
        // flynnlint:parameter NSNumber - alpha component
        let rrr: NSNumber = args[x:0]
        let ggg: NSNumber = args[x:1]
        let bbb: NSNumber = args[x:2]
        let aaa: NSNumber = args[x:3]
        self.setColor(rrr.floatValue, ggg.floatValue, bbb.floatValue, aaa.floatValue)
    }

    lazy var beAlpha = ChainableBehavior<T> { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter Float - alpha component
        self.color.a = args[x:0]
    }

    lazy var beRGBA = ChainableBehavior<T> { [unowned self] (args: BehaviorArgs) in
        // flynnlint:parameter UInt32 - color as an UInt32 (ie 0xFF00FFFF)
        let ccc: UInt32 = args[x:0]
        let rrr = Float((ccc >> 24) & 0xFF) / 255.0
        let ggg = Float((ccc >> 16) & 0xFF) / 255.0
        let bbb = Float((ccc >> 8) & 0xFF) / 255.0
        let aaa = Float((ccc >> 0) & 0xFF) / 255.0
        self.color = GLKVector4Make(rrr, ggg, bbb, aaa)
    }

    lazy var beClear = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0, 0, 0, 0)
    }

    lazy var beWhite = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(1, 1, 1, 1)
    }

    lazy var beBlack = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0, 0, 0, 1)
    }

    lazy var beGray = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0.7, 0.7, 0.7, 1.0)
    }

    lazy var beRed = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(1, 0, 0, 1)
    }

    lazy var beGreen = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0, 1, 0, 1)
    }

    lazy var beBlue = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0, 0, 1, 1)
    }

    lazy var beYellow = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(1, 1, 0, 1)
    }

    lazy var beMagenta = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(1, 0, 1, 1)
    }

    lazy var beCyan = ChainableBehavior<T> { [unowned self] (_: BehaviorArgs) in
        self.setColor(0, 1, 1, 1)
    }

    init (_ actor: T) {
        beColor.setActor(actor)
        beAlpha.setActor(actor)
        beRGBA.setActor(actor)
        beClear.setActor(actor)
        beWhite.setActor(actor)
        beBlack.setActor(actor)
        beGray.setActor(actor)
        beRed.setActor(actor)
        beGreen.setActor(actor)
        beBlue.setActor(actor)
        beYellow.setActor(actor)
        beMagenta.setActor(actor)
        beCyan.setActor(actor)
    }
}

public protocol Colorable: Actor {
    var safeColorable: ColorableState<Self> { get set }
}

public extension Colorable {
    var beColor: ChainableBehavior<Self> { return safeColorable.beColor }
    var beAlpha: ChainableBehavior<Self> { return safeColorable.beAlpha }
    var beRGBA: ChainableBehavior<Self> { return safeColorable.beRGBA }
    var beClear: ChainableBehavior<Self> { return safeColorable.beClear }
    var beWhite: ChainableBehavior<Self> { return safeColorable.beWhite }
    var beBlack: ChainableBehavior<Self> { return safeColorable.beBlack }
    var beGray: ChainableBehavior<Self> { return safeColorable.beGray }
    var beRed: ChainableBehavior<Self> { return safeColorable.beRed }
    var beGreen: ChainableBehavior<Self> { return safeColorable.beGreen }
    var beBlue: ChainableBehavior<Self> { return safeColorable.beBlue }
    var beYellow: ChainableBehavior<Self> { return safeColorable.beYellow }
    var beMagenta: ChainableBehavior<Self> { return safeColorable.beMagenta }
    var beCyan: ChainableBehavior<Self> { return safeColorable.beCyan }
}
