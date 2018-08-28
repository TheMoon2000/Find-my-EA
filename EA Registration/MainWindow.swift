//
//  MainWindow.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/5/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//
//  This class deals with the attributes of the main window.

import Cocoa

var mainWindow: MainWindow? // This is required, because due to Automatic Reference Counting, Swift automatically recycles memory from unreferenced instances. We want to keep this instance.

class MainWindow: NSWindowController, NSWindowDelegate {
    
    @IBOutlet weak var mainwindow: NSWindow!
    
    var resizeDelegate: WindowResizeDelegate?
    
    // This function runs before the window is loaded
    override func windowWillLoad() {
        appWindow = mainwindow
        mainWindow = self
        appWindow?.delegate = self
        mainwindow.delegate = self // Receives and responds to its own actions
        mainwindow.titlebarAppearsTransparent = true // We want to hide the original title bar
        mainwindow.title = "" // We don't need a title either
//        mainwindow.styleMask = 32783
        
        // Adjust color theme according to user settings
        if UserDefaults.standard.bool(forKey: "Blue Theme") {
            mainwindow.backgroundColor = NSColor(red: 0.80, green: 0.88, blue: 0.96, alpha: 1)
        } else {
            mainwindow.backgroundColor = NSColor(red: 0.65, green: 0.18, blue: 0.15, alpha: 0.1)
        }
        mainwindow.isMovableByWindowBackground = true // We want the user to drag the window anywhere where there is no content view.
        mainwindow.isOpaque = false
        mainwindow.standardWindowButton(.zoomButton)?.isHidden = true
    }
    
    // This function runs after the window is loaded (before it's visible to the user)
    override func windowDidLoad() {
        let ap = NSApplication.shared.delegate as! AppDelegate
        self.resizeDelegate = ap.viewController
        
        let zoombutton = ap.viewController?.zoomButton as! ZoomButton
        if !mainwindow.isKeyWindow {zoombutton.unfocus()}
    }
    
    // Runs when the window is about to be resized by the user
    func windowWillStartLiveResize(_ notification: Notification) {
        resizeDelegate?.windowWillResize(nil)
    }
    
    // Runs after the window has been resized
    func windowDidEndLiveResize(_ notification: Notification) {
        resizeDelegate?.windowHasResized(nil)
    }
    
    // Runs before the window is about to go fullscreen
    func windowWillEnterFullScreen(_ notification: Notification) {
        mainwindow.toolbar?.isVisible = false
        mainwindow.standardWindowButton(.zoomButton)?.isHidden = false
        let ap = NSApplication.shared.delegate as! AppDelegate
        let banner = ap.viewController?.topBanner as! TopBanner
        banner.zoomButton.isHidden = true
        mainwindow.title = "Find my EA"
        ap.viewController?.adjustImages(ap.viewController!.message)
    }
    
    // Runs after the window has exited fullscreen
    func windowWillExitFullScreen(_ notification: Notification) {
        mainwindow.toolbar?.isVisible = true
        mainwindow.standardWindowButton(.zoomButton)?.isHidden = true
        let ap = NSApplication.shared.delegate as! AppDelegate
        let banner = ap.viewController?.topBanner as! TopBanner
        banner.zoomButton.isHidden = false
        mainwindow.title = ""
        ap.viewController?.adjustImages(ap.viewController!.message)
    }
    
    // Runs when the window becomes the active one
    func windowDidBecomeKey(_ notification: Notification) {
        let ap = NSApplication.shared.delegate as! AppDelegate
        let zoombutton = ap.viewController?.zoomButton as? ZoomButton
        zoombutton?.focus()
    }
    
    // Runs when the window is no longer focused
    func windowDidResignKey(_ notification: Notification) {
        let ap = NSApplication.shared.delegate as! AppDelegate
        let zoombutton = ap.viewController?.zoomButton as? ZoomButton
        zoombutton?.unfocus()
    }
    
    // For new macs, we will generate a touchbar for the main window.
    
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        guard let viewController = contentViewController as? ViewController else {
            return nil
        }
        return viewController.makeTouchBar()
    }
    
    func windowDidResize(_ notification: Notification) {
        let ap = NSApplication.shared.delegate as! AppDelegate
        DispatchQueue.main.async {
            ap.viewController?.adjustImages(ap.viewController!.message)
            ap.viewController?.adjustImages(ap.viewController!.hiddenMessage)
        }
    }
}

var appWindow: NSWindow? // We keep a global variable so that we can restore the window

// Adjust the coordinate system, so that the origin (0,0) is the bottom left corner.
class CustomView: NSView {
    override var isFlipped: Bool {
        return true
    }
}

// This is the transparent effect on the left side of the window.

class VibrantView: NSVisualEffectView {
    override var allowsVibrancy: Bool {
        return true
    }
    
    // This means the user can drag the window if their cursor is anywhere inside this view.
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    override func updateLayer() {
        super.updateLayer()
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            let string: NSString = "~/Library/Preferences/com.apple.universalaccess.plist"
            let i = NSDictionary(contentsOfFile: string.expandingTildeInPath)!["reduceTransparency"] as? CGFloat ?? 0
            if UserDefaults.standard.bool(forKey: "Blue Theme") {
                self.alphaValue = 1 - i
            }
        }
    }
}

// All images can be dragged

class DraggableImage: NSImageView {
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
}
