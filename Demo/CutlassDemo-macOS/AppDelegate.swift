//
//  AppDelegate.swift
//  CutlassDemo
//
//  Created by Rocco Bowling on 5/19/20.
//  Copyright © 2020 Rocco Bowling. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    @IBAction func switchToExample(_ sender: NSMenuItem) {
        if let window = NSApplication.shared.mainWindow {
            if let viewController = window.contentViewController as? ViewController {
                viewController.switchToDemo(sender.tag)
            }
        }
    }
    
}

