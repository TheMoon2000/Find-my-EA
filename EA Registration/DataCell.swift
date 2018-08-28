//
//  DataCell.swift
//  Whitelist
//
//  Created by Jia Rui Shan on 7/26/16.
//  Copyright © 2016 Tenic. All rights reserved.
//

import Cocoa

class DataCell: NSTableCellView {

    @IBOutlet var cellTitle: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction func deleteItem(_ sender: NSButton) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
            whitelistViewController.deleteCurrentEntry()
        }
    }
    
    @IBAction func editCell(_ sender: NSTextField) {
        whitelistViewController.updateValue(sender.stringValue)
    }
    
    /*
    override var backgroundStyle:NSBackgroundStyle{
        //check value when the style was setted
        didSet{
            //if it is dark the cell is highlighted -> apply the app color to it
            self.wantsLayer = true
            let layersize = self.layer?.frame.size
            let newsize = CGSize(width: (layersize?.width)!+8, height: (layersize?.height)!+8)
            self.layer?.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: newsize)
            if backgroundStyle == .Dark {
                self.layer!.backgroundColor = NSColor(red: 40/255, green: 140/255, blue: 255/255, alpha: 1).CGColor
            }
                //else go back to the standard color
            else{
                self.layer!.backgroundColor = NSColor(white: 1, alpha: 0).CGColor
            }
            
        }
    }*/
}
