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

        /*
        let node = Yoga().fill().rows().itemsStart().wrap().paddingAll(12)
                         .view( Color() )
                         .children([
                            Yoga().size(50%,50%).view( Color().red() ),
                            Yoga().size(50%,50%).view( Color().green() ),
                            Yoga().size(50%,50%).view( Color().blue() ),
                            Yoga().size(50%,50%).view( Color().yellow() )
                         ])
        */
        
        let node = Yoga().fill().rows().center().paddingAll(12)
        .view( Color() )
        .child(
            Yoga().center().size(80%,80%).view( Color().red() ).child(
                Yoga().center().size(80%,80%).view( Color().green() ).child(
                    Yoga().center().size(80%,80%).view( Color().blue() ).child(
                        Yoga().center().size(80%,80%).view( Color().yellow() ).child(
                            Yoga().center().size(80%,80%).view( Color().black() )
                        )
                    )
                )
            )
        )

        // assign our node as the renderer's root...
        cutlassView.renderer().setRoot(node)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

