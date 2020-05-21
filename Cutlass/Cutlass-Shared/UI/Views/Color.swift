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
        let ctx:RenderFrameContext = args[x:0]
        
        // TODO: create and submit the render unit
        
        self.protected_viewableRenderFinished(ctx)
    }
}
