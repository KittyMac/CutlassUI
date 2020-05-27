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
                
        let pathComponents = bundlePath.components(separatedBy: ":/")
        
        switch pathComponents[0] {
        case "http":
            self = bundlePath
            break
        case "https":
            self = bundlePath
            break
        case "assets":
            if let resourcePath = Bundle.main.resourcePath {
                self = "\(resourcePath)/Assets/\(pathComponents[1])"
            }
        case "documents":
            let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
            self = "\(documentsPath)/\(pathComponents[1])"
        case "caches":
            let cachePath = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
            self = "\(cachePath)/\(pathComponents[1])"
        default:
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
