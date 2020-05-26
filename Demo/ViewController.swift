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
        .children([
            Yoga().size(50%,100%).child(
                Yoga().center().size(100%,100%).view( Color().black() ).child(
                    Yoga().center().size(80%,80%).view( Color().green() ).child(
                        Yoga().center().size(80%,80%).view( Color().blue() ).child(
                            Yoga().center().size(80%,80%).view( Color().yellow() ).child(
                                Yoga().center().size(80%,80%).view( Color().red() )
                            )
                        )
                    )
                )
            ),
            
            Yoga().size(50%,100%).rows().itemsStart().wrap().children([
               Yoga().size(50%,50%).view( Color().red() ),
               Yoga().size(50%,50%).view( Color().green() ),
               Yoga().size(50%,50%).view( Color().blue() ),
               Yoga().size(50%,50%).view( Color().yellow() )
            ])
        ])
        cutlassView.renderer().setRoot(node)
    }
    
    func clipDemo() {
        let node = Yoga().fill().rows().itemsStart().paddingAll(12)
            .view( Color().rgba(0.98, 0.98, 0.98, 1.0) )
        .children([
            
            Yoga().size(100,100).view( Color().red().alpha(0.25) ).child(
                Yoga().size(100,100).origin(50%,50%).view( Color().green().alpha(0.25) )
            ),
            
            Yoga().size(100,100).left(100).clips(true).view( Color().red().alpha(0.25) ).child(
                Yoga().size(100,100).origin(50%,50%).view( Color().green().alpha(0.25) )
            ),
            
            Yoga().size(100,100).left(200).clips(true).view( Color().red().alpha(0.25) ).child(
                Yoga().size(100,100).origin(50%,50%).clips(true).view( Color().green().alpha(0.25) ).child(
                    Yoga().size(100,100).origin(-75%,-75%).clips(true).view( Color().blue().alpha(0.25) )
                )
            )
           
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
