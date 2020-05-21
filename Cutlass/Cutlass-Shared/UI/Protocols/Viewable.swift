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

public protocol Viewable : Actor {
    var render:Behavior<Self> { get }
}

public extension Viewable {
    func _viewable_render(_ bounds:GLKVector4) {
        print("Viewable render \(bounds)")
    }
}

