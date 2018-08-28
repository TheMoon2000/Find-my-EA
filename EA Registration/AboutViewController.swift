//
//  AboutViewController.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/30/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

// This is the about view, the cool animation you see when you click “About Find my EA”.

import Cocoa

class AboutViewController: NSViewController {

    @IBOutlet weak var bgImage: LoadImage!
    @IBOutlet weak var maintitle: NSTextField!
    @IBOutlet weak var subtitle: NSTextField!
    @IBOutlet var credits: NSTextView!
    @IBOutlet weak var bottomCredits: NSTextField!
    @IBOutlet weak var version: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        version.stringValue = "Version " + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String) // The app automatically detects and displays its current version

        subtitle.alphaValue = 0 // We are performing a series of animations here, so we start with 0.
        credits.alphaValue = 0
        bottomCredits.alphaValue = 0
        bgImage.fps = 30 // The background animation is made with 30 frames per second
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {self.bgImage.startAnimation("Background")} // After some delay, we begin the bg animation

        // We will begin the animation one by one.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {self.fadeAnimation()}
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {self.creditsAnimation()}
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {self.bottomcreditsAnimation()}
    }
    
    override func viewDidAppear() {
        view.window?.titleVisibility = .hidden
        view.window?.title = "About"
    }
    
    // This function reveals the subtitle -- A new year, and a new start
    func fadeAnimation() {
//        NSAnimationContext.runAnimationGroup({context in
//            context.duration = 1
//            self.subtitle.animator().alphaValue = 1
//            }, completionHandler: nil)
        subtitle.wantsLayer = true
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        subtitle.layer?.add(animation, forKey: "dissolve")
        subtitle.alphaValue = 1
    }
    
    // This function reveals our names. You may add your name (edit in interface builder) if you are a future contributor to our app(s).
    func creditsAnimation() {
        credits.wantsLayer = true
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 1
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        credits.layer?.add(animation, forKey: "CreditsDissolve")
        credits.alphaValue = 1
    }
    
    
    // The bottom description about EA Center appears last.
    func bottomcreditsAnimation() {
        bottomCredits.wantsLayer = true
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        bottomCredits.layer?.add(animation, forKey: "BottomCreditsDissolve")
        bottomCredits.alphaValue = 1
    }
}

// We set a special class “DraggableWindow” for our about window because we want the user to move the window by dragging anywhere, not just the top.
class DraggableWindow: NSWindow {
    override func awakeFromNib() {
        self.isMovableByWindowBackground = true
        self.titlebarAppearsTransparent = true
        self.backgroundColor = NSColor(red: 230/255, green: 247/255, blue: 255/255, alpha: 1)
        self.standardWindowButton(.zoomButton)?.isHidden = true
        self.standardWindowButton(.miniaturizeButton)?.isHidden = true
    }
}
