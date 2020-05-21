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

public final class Color: Actor, Viewable {
    public lazy var render = Behavior(self) { (args:BehaviorArgs) in
        let bounds:GLKVector4 = args[x:0]
        self._viewable_render(bounds)
        print("Color bounds \(bounds)")
    }
}
