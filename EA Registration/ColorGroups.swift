//
//  ColorGroups.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/17/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

let blueColor = NSColor(red: 224/255, green: 237/255, blue: 255/255, alpha: 1).cgColor
let orangeColor = NSColor(red: 1, green: 238/255, blue: 223/255, alpha: 1).cgColor
let yellowColor = NSColor(red: 254/255, green: 254/255, blue: 232/255, alpha: 1).cgColor
let greenColor = NSColor(red: 238/255, green: 255/255, blue: 238/255, alpha: 1).cgColor
let redColor = NSColor(red: 255/255, green: 220/255, blue: 220/255, alpha: 1).cgColor
let pinkColor = NSColor(red: 1, green: 241/255, blue: 253/255, alpha: 1).cgColor
let purpleColor = NSColor(red: 238/255, green: 236/255, blue: 255/255, alpha: 1).cgColor

class ColorGroups: NSView {
    @IBOutlet weak var science: NSButton!
    @IBOutlet weak var design: NSButton!
    @IBOutlet weak var sports: NSButton!
    @IBOutlet weak var humanities: NSButton!
    @IBOutlet weak var literature: NSButton!
    @IBOutlet weak var community: NSButton!
    @IBOutlet weak var recreation: NSButton!
    @IBOutlet weak var others: NSButton!
    
    var currentColor: NSObject = "" as NSObject
    
    var enabled = false
    
    override func awakeFromNib() {
        
        for i in [science, sports, humanities, design, community, literature, recreation, others] {
            i?.wantsLayer = true
            i?.layer?.cornerRadius = 16
            i?.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
            i?.layer?.borderWidth = 1
        }
        
        literature.layer?.backgroundColor = redColor
        science.layer?.backgroundColor = blueColor
        design.layer?.backgroundColor = orangeColor
        sports.layer?.backgroundColor = yellowColor
        humanities.layer?.backgroundColor = greenColor
        community.layer?.backgroundColor = pinkColor
        recreation.layer?.backgroundColor = purpleColor
        others.layer?.backgroundColor = NSColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        
        super.awakeFromNib()
    }
    
    @IBAction func science(_ sender: NSButton) {
        if !enabled {return}
        let ap = NSApplication.shared.delegate as! AppDelegate
        let vc = ap.viewController
        var newColor = ""
        switch sender {
        case science:
            newColor = "Blue"
        case design:
            newColor = "Orange"
        case sports:
            newColor = "Yellow"
        case humanities:
            newColor = "Green"
        case literature:
            newColor = "Red"
        case community:
            newColor = "Pink"
        case recreation:
            newColor = "Purple"
        case others:
            newColor = ""
        default:
            break
        }
        if currentColor == sender {
            lighten(sender)
            vc!.filterEA("_")
            currentColor = "" as NSObject
//            vc!.searchField.isEnabled = true
        } else if currentColor as? String != "" {
            lighten(currentColor as! NSButton)
            darken(sender)
//            vc.filterEA("")
            vc!.filterEA(newColor)
            currentColor = sender
//            vc!.searchField.isEnabled = false
        } else {
            darken(sender)
            vc!.filterEA(newColor)
            currentColor = sender
//            vc!.searchField.isEnabled = false
        }
    }
    
    func lighten(_ button: NSButton) {
        let color = NSColor(cgColor: button.layer!.backgroundColor!)!
        let red = color.redComponent + 0.1
        let green = color.greenComponent + 0.1
        let blue = color.blueComponent + 0.1
        let alpha = color.alphaComponent
        button.layer?.backgroundColor = NSColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
        button.layer?.borderColor = NSColor(white: 0.9, alpha: 1).cgColor
    }
    
    func darken(_ button: NSButton) {
        let color = NSColor(cgColor: button.layer!.backgroundColor!)!
        let red = color.redComponent - 0.1
        let green = color.greenComponent - 0.1
        let blue = color.blueComponent - 0.1
        let alpha = color.alphaComponent
        button.layer?.backgroundColor = NSColor(red: red, green: green, blue: blue, alpha: alpha).cgColor
        button.layer?.borderColor = NSColor(white: 0.8, alpha: 1).cgColor
    }
    
    func reset() {
        if currentColor as? String != "" {
            lighten(currentColor as! NSButton)
            currentColor = "" as NSObject
//            let ap = NSApplication.shared().delegate as! AppDelegate
//            ap.viewController!.removedRows.removeAllIndexes()
        }
    }
}
