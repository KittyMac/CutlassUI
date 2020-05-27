//
//  String+Bundle.swift
//  PlanetSwift
//
//  Created by Brad Bambara on 1/13/15.
//  Copyright (c) 2015 Small Planet. All rights reserved.
//

import Foundation

extension String {
    public init(bundlePath:String, defaultExt:String = "png") {
        // name is a "url path" to a file.  These are like in planet:
        // "resources://landscape_desert.jpg"
        // "documents://landscape_desert.jpg"
        // "caches://landscape_desert.jpg"
        self.init()
        
        if bundlePath.starts(with: "http://") || bundlePath.starts(with: "https://") {
            self = bundlePath
            return
        } else if bundlePath.starts(with: "assets://") {
            if let resourcePath = Bundle.main.resourcePath {
                self = "\(resourcePath)/Assets/\(bundlePath.dropFirst(9))"
            }
        } else if bundlePath.starts(with: "documents://") {
           let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
           self = "\(documentsPath)/\(bundlePath.dropFirst(12))"
        } else if bundlePath.starts(with: "caches://") {
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            self = "\(cachePath)/\(bundlePath.dropFirst(9))"
        } else {
            // we default to resources:// and ".png" so that things like "imagename" are easy and possible
            if let resourcePath = Bundle.main.resourcePath {
                let ext = (bundlePath as NSString).pathExtension
                if ext.count == 0 {
                    self = "\(resourcePath)/Assets/\(bundlePath).\(defaultExt)"
                }else{
                    self = "\(resourcePath)/Assets/\(bundlePath)"
                }
            }
        }
    }
}
