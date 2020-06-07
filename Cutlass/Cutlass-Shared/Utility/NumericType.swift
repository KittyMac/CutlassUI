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

public protocol CutlassNumericType: Comparable {
    var value: Float { get set }
    init(_ value: Float)
}

public func + <T: CutlassNumericType> (lhs: T, rhs: T) -> T {
    return T(lhs.value + rhs.value)
}

public func - <T: CutlassNumericType> (lhs: T, rhs: T) -> T {
    return T(lhs.value - rhs.value)
}

public func < <T: CutlassNumericType> (lhs: T, rhs: T) -> Bool {
    return lhs.value < rhs.value
}

public func == <T: CutlassNumericType> (lhs: T, rhs: T) -> Bool {
    return lhs.value == rhs.value
}

public prefix func - <T: CutlassNumericType> (number: T) -> T {
    return T(-number.value)
}

public func += <T: CutlassNumericType> (lhs: inout T, rhs: T) {
    lhs.value += rhs.value
}

public func -= <T: CutlassNumericType> (lhs: inout T, rhs: T) {
    lhs.value -= rhs.value
}
