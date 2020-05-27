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

public final class Image: Actor, Viewable, Colorable, Imageable {
    public lazy var _colorable = ColorableState(self)
    public lazy var _imageable = ImageableState(self)
    
    private var bufferedGeometry = BufferedGeometry()
    
    public lazy var render = Behavior(self) { (args:BehaviorArgs) in
        let ctx:RenderFrameContext = args[x:0]
        let bounds = ctx.view.bounds
        
        let geom = self.bufferedGeometry.next()
        let vertices = geom.vertices
        
        self.protected_imageable_confirmImageSize(ctx)
                
        if geom.check(ctx, self._imageable._image_hash) == false {
            self.protected_imageable_fillVertices(ctx,
                                                  self._colorable._color,
                                                  bounds,
                                                  vertices)
        }
        
        self.protected_viewable_submitRenderUnit(ctx,
                                                 vertices,
                                                 self._imageable._image_size,
                                                 .texture,
                                                 self._imageable._path)
        
        self.protected_viewable_submitRenderFinished(ctx)
    }
}
