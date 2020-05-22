//
//  ViewController.swift
//  CutlassDemo-iOS
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import UIKit
import Cutlass
import Flynn

class ViewController: UIViewController {

    @IBOutlet var cutlassView: CutlassView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let node = Yoga().fill().rows().itemsStart().wrap().paddingAll(px: 12)
        .view( Color() )
        .children([
            Yoga().sizePercent(50,50).view( Color().red() ),
            Yoga().sizePercent(50,50).view( Color().green() ),
            Yoga().sizePercent(50,50).view( Color().blue() ),
            Yoga().sizePercent(50,50).view( Color().yellow() )
        ])
        
        // assign our node as the renderer's root...
        cutlassView.renderer().setRoot(node)
        
    }


}

