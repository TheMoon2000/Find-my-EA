//
//  MapWindowController.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/24/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

class MapWindowController: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var mapWindow: NSWindow!

    override func windowDidLoad() {
        super.windowDidLoad()
        let ap = NSApplication.shared.delegate as! AppDelegate
        ap.map_Window = mapWindow
        mapWindow.delegate = self
        mapWindow.titlebarAppearsTransparent = true
//        mapWindow.backgroundColor = NSColor(red: 57/255, green: 137/255, blue: 185/255, alpha: 1)
    }
    
    func windowWillEnterFullScreen(_ notification: Notification) {
//        let vc = self.contentViewController as! MapViewController
//        vc.bannerImage.hidden = true
        mapWindow.title = "Campus Map"
    }
    
    func windowWillExitFullScreen(_ notification: Notification) {
//        let vc = self.contentViewController as! MapViewController
//        vc.bannerImage.hidden = false
        mapWindow.title = ""
    }

}
