//
//  Yoga.swift
//  Cutlass
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//
// https://fabiancanas.com/blog/2015/5/21/making-a-numeric-type-in-swift.html

import Foundation
import Cutlass.Yoga
import GLKit
import Flynn

postfix operator %
public postfix func % (p: Float) -> Percentage {
    return Percentage(p)
}

public struct Percentage :CutlassNumericType {
    public var value :Float
    public init(_ value: Float) {
        self.value = value
    }
    public init(_ value: CGFloat) {
        self.value = Float(value)
    }
}
