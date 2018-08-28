//
//  EACellView.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/3/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

class EACellView: NSTableCellView {

    @IBOutlet weak var eaLabel: NSTextField!
    @IBOutlet weak var bottomLine: NSBox!
    @IBOutlet weak var image: NSImageView!
    
    var digit = 0 {
        didSet {
            if digit <= 0 {
                numberOfFavorites.stringValue = ""
                digit = 0
            } else {
                numberOfFavorites.integerValue = digit
            }
        }
    }
    @IBOutlet weak var numberOfFavorites: NSTextField!
    
    let d = UserDefaults.standard
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.wantsLayer = true
        
        switch eaLabel.stringValue {
        case "All EAs":
            image.image = eaLabel.alphaValue == 0.99 ? NSImage(named: NSImage.Name(rawValue: "All")) : #imageLiteral(resourceName: "All_highlighted")
        case "EAs Pending":
            image.image = eaLabel.alphaValue == 0.99 ? NSImage(named: NSImage.Name(rawValue: "Clock")) : #imageLiteral(resourceName: "Clock_highlighted")
        case "EAs I Joined":
            image.image = eaLabel.alphaValue == 0.99 ? NSImage(named: NSImage.Name(rawValue: "Joined")) : #imageLiteral(resourceName: "Joined_highlighted")
        case "Favorites":
            image.image = #imageLiteral(resourceName: "Favorite")
        default:
            break
        }
    }
    
    var currentRow: Int {
        let ap = NSApplication.shared.delegate as! AppDelegate
        return ap.viewController!.nextEATableViewRow
    }
    
    func rowAtIndex(_ index: Int) -> EACellView? {
        let ap = NSApplication.shared.delegate as! AppDelegate
        return ap.viewController?.EATableView.view(atColumn: 0, row: index, makeIfNecessary: false) as? EACellView

    }

    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            if backgroundStyle == .dark || rowAtIndex(currentRow)?.eaLabel.stringValue == self.eaLabel.stringValue {
                eaLabel.textColor = NSColor.white
                if d.bool(forKey: "Blue Theme") {
                    if !(self.backgroundStyle == .dark) {
                        self.backgroundStyle = .dark
                        self.layer?.backgroundColor = selectionLightBlueColor.cgColor
                    } else {
                        self.layer?.backgroundColor = selectionBlueColor.cgColor
                    }
                } else {
                    if !(self.backgroundStyle == .dark) {
                        self.backgroundStyle = .dark
                        self.layer?.backgroundColor = selectionLightRedColor.cgColor
                    } else {
                        self.layer?.backgroundColor = selectionRedColor.cgColor
                    }
                }
                bottomLine.isHidden = true
                eaLabel.alphaValue = 1
                
                var rows = Array(0...3); rows.remove(at: currentRow)
                for i in rows {
                    rowAtIndex(i)?.backgroundStyle = .light
                }
                self.numberOfFavorites.textColor = NSColor.white
            } else {
                eaLabel.textColor = NSColor.black
                eaLabel.alphaValue = 0.99
                self.layer?.backgroundColor = NSColor.clear.cgColor
                bottomLine.isHidden = false
                self.numberOfFavorites.textColor = digitColor
            }
            self.draw(self.frame)
        }
    }
    
}
