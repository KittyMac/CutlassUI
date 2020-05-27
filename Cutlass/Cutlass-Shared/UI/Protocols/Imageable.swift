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

public enum ImageModeType {
    case fill
    case aspectFill
    case aspectFit
    case stretch
}

public class ImageableState {
    var _image_hash:Int = 0
    var _image_width:Int = 0
    var _image_height:Int = 0
    var _image_aspect:Float = 0
    
    var _path:String? = nil
    var _mode:ImageModeType = .fill
    var _sizeToFit:Bool = false
    var _stretchInsets:GLKVector4 = GLKVector4Make(0,0,0,0)
    
    var path:Behavior? = nil
    var mode:Behavior? = nil
    var sizeToFit:Behavior? = nil
    var stretchInsets:Behavior? = nil
    
    init (_ actor:Actor) {
        path = Behavior(actor) { (args:BehaviorArgs) in
            self._path = args[x:0]
        }
        mode = Behavior(actor) { (args:BehaviorArgs) in
            self._mode = args[x:0]
        }
        sizeToFit = Behavior(actor) { (args:BehaviorArgs) in
            self._sizeToFit = args[x:0]
        }
        stretchInsets = Behavior(actor) { (args:BehaviorArgs) in
            self._stretchInsets = args[x:0]
        }
    }
}

public protocol Imageable : Actor {
    var _imageable:ImageableState { get set }
}

public extension Imageable {
    func path(_ p:String) -> Self {
        _imageable.path!(p)
        return self
    }
    func sizeToFit(_ p:Bool) -> Self {
        _imageable.sizeToFit!(p)
        return self
    }
    
    func stretch(_ top:Float, _ left:Float, _ bottom:Float, _ right:Float) -> Self {
        _imageable.stretchInsets!(GLKVector4Make(top,left,bottom,right))
        return self
    }
    
    func stretchAll(_ v:Float) -> Self {
        _imageable.stretchInsets!(GLKVector4Make(v,v,v,v))
        return self
    }
    
    func fill() -> Self {
        _imageable.mode!(ImageModeType.fill)
        return self
    }
    func aspectFit() -> Self {
        _imageable.mode!(ImageModeType.aspectFit)
        return self
    }
    func aspectFill() -> Self {
        _imageable.mode!(ImageModeType.aspectFill)
        return self
    }
    
    func imageLoaded() -> Bool {
        return (_imageable._image_width != 0) || (_imageable._image_height != 0)
    }
    
    func protected_imageable_confirmImageSize(_ ctx:RenderFrameContext) {
        if let path = _imageable._path {
            if (imageLoaded() == false) {
                if let textureInfo = ctx.renderer.getTexture(path) {
                    _imageable._image_width = textureInfo.width
                    _imageable._image_height = textureInfo.height
                    _imageable._image_aspect = Float(textureInfo.width) / Float(textureInfo.height)
                    _imageable._image_hash = textureInfo.width + textureInfo.height + path.hashValue
                }
            }
        }
    }
    
    func protected_imageable_fillVertices(_ ctx:RenderFrameContext,
                                          _ color:GLKVector4,
                                          _ bounds:GLKVector4,
                                          _ vertices:FloatAlignedArray) {
        vertices.reserve(6 * 7)
        vertices.clear()
        
        if imageLoaded() {
            let image_aspect = _imageable._image_aspect
            let bounds_aspect = bounds.z / bounds.w
            
            var x_min = bounds.xMin()
            var y_min = bounds.yMin()
            var x_max = bounds.xMax()
            var y_max = bounds.yMax()
            
            var s_min:Float = 0.0
            var s_max:Float = 1.0
            var t_min:Float = 0.0
            var t_max:Float = 1.0
            
            if _imageable._mode == .aspectFit {
                if image_aspect > bounds_aspect {
                    let c = (y_min + y_max) / 2
                    let h = (x_max - x_min) / image_aspect
                    y_min = c - (h / 2)
                    y_max = c + (h / 2)
                } else {
                    let c = (x_min + x_max) / 2
                    let w = (y_max - y_min) * image_aspect
                    x_min = c - (w / 2)
                    x_max = c + (w / 2)
                }
            } else if _imageable._mode == .aspectFill {
                let combined_aspect = (image_aspect / bounds_aspect)
                if combined_aspect > 1.0 {
                    s_min = 0.5 - ((1.0 / combined_aspect) / 2)
                    s_max = 0.5 + ((1.0 / combined_aspect) / 2)
                } else {
                    t_min = 0.5 - (combined_aspect / 2)
                    t_max = 0.5 + (combined_aspect / 2)
                }
            }
            

            vertices.pushQuadVCT(ctx.view.matrix,
                                 GLKVector3Make(x_min, y_min, 0),
                                 GLKVector3Make(x_max, y_min, 0),
                                 GLKVector3Make(x_max, y_max, 0),
                                 GLKVector3Make(x_min, y_max, 0),
                                 color,
                                 GLKVector2Make(s_min, t_min),
                                 GLKVector2Make(s_max, t_min),
                                 GLKVector2Make(s_max, t_max),
                                 GLKVector2Make(s_min, t_max))
        }
    }
}

