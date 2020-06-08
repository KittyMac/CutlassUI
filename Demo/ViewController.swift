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
        switchToDemo(2)
    }
    
    func colorsDemo() {
        let node = Yoga().fill().rows().center().paddingAll(12)
            .children([
                Yoga().size(50%,100%).child(
                    Yoga().center().fill().view( Color().beBlack() ).child(
                        Yoga().center().size(80%,80%).view( Color().beGreen() ).child(
                            Yoga().center().size(80%,80%).view( Color().beBlue() ).child(
                                Yoga().center().size(80%,80%).view( Color().beYellow() ).child(
                                    Yoga().center().size(80%,80%).view( Color().beRed() )
                                )
                            )
                        )
                    )
                ),
                
                Yoga().size(50%,100%).rows().itemsStart().wrap().children([
                   Yoga().size(50%,50%).view( Color().beRed() ),
                   Yoga().size(50%,50%).view( Color().beGreen() ),
                   Yoga().size(50%,50%).view( Color().beBlue() ),
                   Yoga().size(50%,50%).view( Color().beYellow() )
                ])
            ])
        cutlassView.renderer().beSetRoot(node)
    }
    
    func clipDemo() {
        let node = Yoga().fill().rows().itemsStart().paddingAll(12)
            .view( Color().beColor(0.98, 0.98, 0.98, 1.0) )
            .children([
                
                Yoga().size(100,100).view( Color().beRed().beAlpha(0.25) ).child(
                    Yoga().size(100,100).origin(50%,50%).view( Color().beGreen().beAlpha(0.25) )
                ),
                
                Yoga().size(100,100).left(100).clips(true).view( Color().beRed().beAlpha(0.25) ).child(
                    Yoga().size(100,100).origin(50%,50%).view( Color().beGreen().beAlpha(0.25) )
                ),
                
                Yoga().size(100,100).left(200).clips(true).view( Color().beRed().beAlpha(0.25) ).child(
                    Yoga().size(100,100).origin(50%,50%).clips(true).view( Color().beGreen().beAlpha(0.25) ).child(
                        Yoga().size(100,100).origin(-75%,-75%).clips(true).view( Color().beBlue().beAlpha(0.25) )
                    )
                )
               
            ])
        cutlassView.renderer().beSetRoot(node)
    }
    
    func imageDemo() {
        let node = Yoga().fill().rows().itemsStart().wrap().paddingAll(12)
            .view( Color().beColor(0.98, 0.98, 0.98, 1.0) )
            .children([
                
                Yoga().size(100,100).sizeToFit(true).view( Image().bePath("unpressed_button") ),
                Yoga().size(100,100).sizeToFit(true).view( Image().bePath("unpressed_button").beRed() ),
                Yoga().size(100,100).sizeToFit(true).view( Image().bePath("unpressed_button").beGreen() ),
                Yoga().size(100,100).sizeToFit(true).view( Image().bePath("unpressed_button").beBlue() ),
                Yoga().size(100,100).sizeToFit(true).view( Image().bePath("unpressed_button").beRGBA(0xFFFFFF33) ),
                                
                Yoga().size(128,256)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beFill() ),
                
                Yoga().size(128,256)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beAspectFit() ),
                
                Yoga().size(128,256)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beAspectFill() ),
                
                Yoga().size(256,128)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beFill() ),
                
                Yoga().size(256,128)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beAspectFit() ),
                
                Yoga().size(256,128)
                    .view( Color().beGray() )
                    .view( Image().bePath("landscape_desert").beAspectFill() )
                   
            ])
        cutlassView.renderer().beSetRoot(node)
    }
    
    func switchToDemo(_ n:Int) {
        switch n {
        case 0:
            colorsDemo()
            break
        case 1:
            clipDemo()
            break
        case 2:
            imageDemo()
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
