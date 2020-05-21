//
//  ViewController.swift
//  CutlassDemo
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Cocoa
import Cutlass
import Flynn

class ViewController: NSViewController {
    
    @IBOutlet var cutlassView: CutlassView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let node = Yoga().size(1024,768).center().top(percent:10)
                         .view( Color() )
                         .view( Color() )
                         .view( Color() )
                         .view( Color() )
                         .view( Color() )
                         .view( Color() )
        
        // assign our node as the renderer's root...
        cutlassView.renderer().setRoot(node)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

