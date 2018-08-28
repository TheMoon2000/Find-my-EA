//
//  EADetailTable.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/23/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

class TopBanner: NSView {
    @IBOutlet weak var mapImage: NSImageView!
    @IBOutlet weak var mapLabel: NSTextField!
    @IBOutlet weak var mapButton: NSButton!
    @IBOutlet weak var mapImage_highlighted: NSImageView!
    @IBOutlet weak var mapLabel_highlighted: NSTextField!
    @IBOutlet weak var bannerBackground: NSImageView!
    @IBOutlet weak var zoomButton: NSButton!
    
    var startTime = 0.0
    
    var entered = false
    
    override func awakeFromNib() {
        mapButton.addTrackingArea(NSTrackingArea(rect: mapButton.bounds, options: NSTrackingArea.Options(rawValue: 129), owner: self, userInfo: nil))
        if UserDefaults.standard.bool(forKey: "Blue Theme") {
            mapImage.image = #imageLiteral(resourceName: "Marker")
            bannerBackground.image = #imageLiteral(resourceName: "top_gradient_blue")
        } else {
            mapImage.image = #imageLiteral(resourceName: "Marker_red")
            bannerBackground.image = #imageLiteral(resourceName: "top_gradient")
            mapLabel.textColor = NSColor(red: 1, green: 0.97, blue: 0.97, alpha: 0.98)
        }
    }
    
    func down() {
        mapImage.alphaValue = 0
        mapImage_highlighted.alphaValue = 0.9
        mapLabel.alphaValue = 0
        mapLabel_highlighted.alphaValue = 0.9
        mapLabel_highlighted.layer?.removeAllAnimations()
        mapImage_highlighted.layer?.removeAllAnimations()
    }
    
    func up() {
        if entered {
            mapImage_highlighted.alphaValue = 0.99
            mapLabel_highlighted.alphaValue = 0.99
            mapImage.alphaValue = 0
            mapLabel.alphaValue = 0
            let ap = NSApplication.shared.delegate as! AppDelegate
            ap.viewController?.openMap()
        } else {
            mapImage_highlighted.alphaValue = 0
            mapLabel_highlighted.alphaValue = 0
            mapImage.alphaValue = 0.99
            mapLabel.alphaValue = 0.99
        }

    }
    
    override func mouseEntered(with theEvent: NSEvent) {
        entered = true
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 0.99
        animation.duration = 0.35
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        mapImage_highlighted.wantsLayer = true
        mapImage_highlighted.alphaValue = 0.99
        mapLabel_highlighted.alphaValue = 0.99
        mapImage_highlighted.layer?.add(animation, forKey: "dissolveAnimation")
        mapLabel_highlighted.wantsLayer = true
        mapLabel_highlighted.layer?.add(animation, forKey: "dissolveLabel")
        startTime = Date.timeIntervalSinceReferenceDate
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        entered = false
        let newTime = Date.timeIntervalSinceReferenceDate - startTime
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0.99
        animation.toValue = 0
        animation.duration = 0.35
        animation.beginTime = newTime >= 0.35 ? 0 : 0.35 - newTime
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        mapImage_highlighted.alphaValue = 0
        mapImage.alphaValue = 0.99
        mapLabel.alphaValue = 0.99
        mapLabel_highlighted.alphaValue = 0
        mapImage_highlighted.layer?.removeAllAnimations()
        mapLabel_highlighted.layer?.removeAllAnimations()
        mapImage_highlighted.layer?.add(animation, forKey: "dissolveAnimation")
        mapLabel_highlighted.layer?.add(animation, forKey: "dissolveLabel")
        
    }
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    @IBAction func toggleFullScreen(_ sender: NSButton) {
        self.window?.toggleFullScreen(sender)
    }
}

class MapButton: NSButton {
    override func awakeFromNib() {
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: 129), owner: self, userInfo: nil))
    }
    override func mouseUp(with theEvent: NSEvent) {
        let ap = NSApplication.shared.delegate as! AppDelegate
        let banner = ap.viewController?.topBanner as! TopBanner
        banner.up()
    }
    override func mouseDown(with theEvent: NSEvent) {
        let ap = NSApplication.shared.delegate as! AppDelegate
        let banner = ap.viewController?.topBanner as! TopBanner
        banner.down()
    }
}

class Banner: NSImageView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}

class ZoomButton: NSButton {
    
    var inside = false
    var down = false
    
    var windowfocus = true
    
    override func awakeFromNib() {
        self.addTrackingArea(NSTrackingArea(rect: self.bounds, options: NSTrackingArea.Options(rawValue: 129), owner: self, userInfo: nil))
    }
    override func mouseEntered(with theEvent: NSEvent) {
        inside = true
        self.image = #imageLiteral(resourceName: "enterfullscreen")
    }
    
    override func mouseExited(with theEvent: NSEvent) {
        inside = false
        self.image = #imageLiteral(resourceName: "zoombutton")
        if !windowfocus {unfocus()}
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        down = true
        self.image = #imageLiteral(resourceName: "enterfullscreendown")
    }
    
    override func mouseUp(with theEvent: NSEvent) {
        down = false
        if inside {
//            self.image = NSImage(named: "enterfullscreen@2x.png")
            self.window?.toggleFullScreen(self)
        }
        self.image = #imageLiteral(resourceName: "zoombutton")
    }
    
    func unfocus() {
        windowfocus = false
        self.image = #imageLiteral(resourceName: "zoombutton_unfocused")
    }
    
    func focus() {
        windowfocus = true
        self.image = #imageLiteral(resourceName: "zoombutton")
    }
}
