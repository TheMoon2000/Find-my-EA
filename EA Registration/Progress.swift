//
//  Progress.swift
//  Progress
//
//  Created by Jia Rui Shan on 2/4/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Cocoa

class Progress: NSView {
    
    var backgroundColor = NSColor(white: 1, alpha: 0.1)
    var progressColor = NSColor(white: 1, alpha: 0.6)
    
    @objc dynamic var percentage: CGFloat = 0 {
        didSet {
            self.needsDisplay = true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
//        let diameter = self.frame.width
//        self.wantsLayer = true
//        self.layer?.cornerRadius = diameter / 2
//        self.layer?.backgroundColor = backgroundColor.CGColor
        let bezier = NSBezierPath()
        let center = NSMakePoint(NSMidX(self.bounds), NSMidY(self.bounds))
        bezier.appendArc(withCenter: center, radius: self.self.frame.width / 2, startAngle: 90, endAngle: 90 - 360 * percentage, clockwise: true)
        bezier.lineWidth = 2.5
        progressColor.set()
        bezier.stroke()
    }
    
//    func setPercentage(value: CGFloat) {
//        
//    }
//    
    override func awakeFromNib() {
        let diameter = self.frame.width
        self.wantsLayer = true
        self.layer?.cornerRadius = diameter / 2
    }
    
}
