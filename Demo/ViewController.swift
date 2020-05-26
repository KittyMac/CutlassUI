//
//  ViewController.swift
//  CutlassDemo
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//


import Cutlass
import Flynn

#if os(macOS)
import Cocoa
import AppKit
typealias SharedController = NSViewController
#else
import UIKit
typealias SharedController = UIViewController
#endif

class ViewController: SharedController {
    
    @IBOutlet var cutlassView: CutlassView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        colorsDemo()
    }
    
    func colorsDemo() {
        let node = Yoga().fill().rows().center().paddingAll(12)
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
        cutlassView.renderer().setRoot(node)
    }
    
    func clipDemo() {
        let node = Yoga().fill().rows().itemsStart().wrap().paddingAll(12)
        .view( Color() )
        .children([
           Yoga().size(50%,50%).view( Color().red() ),
           Yoga().size(50%,50%).view( Color().green() ),
           Yoga().size(50%,50%).view( Color().blue() ),
           Yoga().size(50%,50%).view( Color().yellow() )
        ])
        cutlassView.renderer().setRoot(node)
    }
    
    func switchToDemo(_ n:Int) {
        switch n {
        case 0:
            colorsDemo()
            break
        case 1:
            clipDemo()
            break
        default:
            break
        }
    }
}

/*
class ViewController: UIViewController {

    @IBOutlet var cutlassView: CutlassView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let node = Yoga().fill().rows().itemsStart().wrap().paddingAll(12)
                         .view( Color() )
                         .children([
                            Yoga().size(50%,50%).view( Color().red() ),
                            Yoga().size(50%,50%).view( Color().green() ),
                            Yoga().size(50%,50%).view( Color().blue() ),
                            Yoga().size(50%,50%).view( Color().yellow() )
                         ])

        // assign our node as the renderer's root...
        cutlassView.renderer().setRoot(node)
        
    }


}



*/
