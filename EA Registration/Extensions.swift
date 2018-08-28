//
//  String Extension.swift
//  Found my EA
//
//  Created by Jia Rui Shan on 1/7/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

import Foundation

let replaceScheme = [("__sq__", "'"), ("__dq__", "\""), ("__am__", "&"), ("__eq__", "="), ("__sc__", ";")]

extension String {
    var decodedString: String {
        var tmp = self
        for i in replaceScheme {
            tmp = tmp.replacingOccurrences(of: i.0, with: i.1)
        }
        return tmp
    }
    
    var encodedString: String {
        var tmp = self
        for i in replaceScheme {
            tmp = tmp.replacingOccurrences(of: i.1, with: i.0)
        }
        return tmp
    }
}

extension NSImage {
    func resizeToFit(containerWidth: CGFloat) {
        let currentWidth = self.size.width
        let currentHeight = self.size.height
        if currentWidth < containerWidth * 0.95 {return}
        var scaleFactor : CGFloat = 1.0
        if currentWidth > containerWidth {
            scaleFactor = (containerWidth * 0.95) / currentWidth
        }
        let newWidth = currentWidth * scaleFactor
        let newHeight = currentHeight * scaleFactor
        
        self.size = NSSize(width: newWidth, height: newHeight)
    }
    
    var resolution: NSSize {
        let factor = NSScreen.main!.backingScaleFactor
        return NSMakeSize(CGFloat(self.representations[0].pixelsWide) / factor,
                          CGFloat(self.representations[0].pixelsHigh) / factor)
    }
}

extension NSTextView {
    func getParts() -> [NSAttributedString] {
        var parts = [NSAttributedString]()
        
        let attributedString = self.attributedString()
        let range = NSMakeRange(0, attributedString.length)
        attributedString.enumerateAttributes(in: range, options: .init(rawValue: 0)) { (object, range, stop) in
            parts.append(attributedString.attributedSubstring(from: range))
        }
        
        return parts
    }
    
    func getAlignImages() -> [NSImage] {
        var images = [NSImage]()
        
        let attributedString = self.attributedString()
        let range = NSMakeRange(0, attributedString.length)
        attributedString.enumerateAttributes(in: range, options: .init(rawValue: 0)) { (object, range, stop) in
            
            if object.keys.contains(NSAttributedStringKey.attachment) {
                if let attachment = object[NSAttributedStringKey.attachment] as? NSTextAttachment {
                    if #available(OSX 10.11, *) {
                        if let image = attachment.image {
                            images.append(image)
                        } else if let image = attachment.image(forBounds: attachment.bounds, textContainer: nil, characterIndex: range.location) {
                            images.append(image)
                        }
                    }
                }
            }
        }
        
        return images
    }
    
    func getAttributedAlignImages() -> [NSAttributedString] {
        var images = [NSAttributedString]()
        
        let attributedString = self.attributedString()
        let range = NSMakeRange(0, attributedString.length)
        attributedString.enumerateAttributes(in: range, options: .init(rawValue: 0)) { (object, range, stop) in
            
            if object.keys.contains(NSAttributedStringKey.attachment) {
                if object[NSAttributedStringKey.attachment] as? NSTextAttachment != nil {
                    if #available(OSX 10.11, *) {
                        images.append(attributedString.attributedSubstring(from: range))
                    }
                }
            }
        }
        
        return images
    }
}
