//
//  EAInfo.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/3/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

let selectionBlueColor = NSColor(red: 30/255, green: 135/255, blue: 200/255, alpha: 1)
let selectionLightBlueColor = NSColor(red: 48/255, green: 153/255, blue: 218/255, alpha: 1)
let selectionRedColor = NSColor(red: 200/255, green: 73/255, blue: 68/255, alpha: 1)
let selectionLightRedColor = NSColor(red: 222/255, green: 93/255, blue: 90/255, alpha: 1)

let digitColor = NSColor(white: 0.4, alpha: 0.8)


class EAInfo: NSTableCellView {

    @IBOutlet weak var EAname: NSTextField!
    @IBOutlet weak var EAdescription: NSTextField!
    @IBOutlet weak var EATime: NSTextField!
    @IBOutlet weak var white: NSView!
    @IBOutlet weak var background: NSView!
    @IBOutlet weak var bottomLine: NSBox!
    
    @IBOutlet weak var like: NSButton!
    @IBOutlet weak var numberOfLikes: NSTextField!
    
    let d = UserDefaults.standard
    
    let vc = (NSApplication.shared.delegate as! AppDelegate).viewController!
    
    var enabled = true {
        didSet {
            white.isHidden = enabled
        }
    }
    
    var color: String = "" {
        didSet {
            background.wantsLayer = true
            switch color {
            case "Blue":
                background.layer?.backgroundColor = blueColor
            case "Orange":
                background.layer?.backgroundColor = orangeColor
            case "Green":
                background.layer?.backgroundColor = greenColor
            case "Pink":
                background.layer?.backgroundColor = pinkColor
            case "Red":
                background.layer?.backgroundColor = redColor
            case "Yellow":
                background.layer?.backgroundColor = yellowColor
            case "Purple":
                background.layer?.backgroundColor = purpleColor
            default:
                background.layer?.backgroundColor = NSColor(white: 1, alpha: 0.8).cgColor
            }
        }
    }
    
    override func awakeFromNib() {
        white.wantsLayer = true
        white.layer?.backgroundColor = NSColor(white: 1, alpha: 0.6).cgColor
        
//        EAdescription.wantsLayer = true
//        EAdescription.layer?.borderWidth = 1
//        EAdescription.layer?.borderColor = NSColor.blackColor().CGColor
    }
    
    override var backgroundStyle: NSView.BackgroundStyle {
        didSet {
            if backgroundStyle == .dark {
                EAname.textColor = NSColor.white
                EAdescription.textColor = NSColor.white
                EATime.textColor = NSColor.white
                background.isHidden = true
                if d.bool(forKey: "Blue Theme") {
                    self.layer?.backgroundColor = selectionBlueColor.cgColor
                } else {
                    self.layer?.backgroundColor = selectionRedColor.cgColor
                }
                bottomLine.isHidden = true
                if like.image == #imageLiteral(resourceName: "Favorite_outline") {like.image = #imageLiteral(resourceName: "Favorite_dark")}
            } else if backgroundStyle == .light {
                EAname.textColor = NSColor.black
                EAdescription.textColor = NSColor.black
                EATime.textColor = NSColor(white: 0.4, alpha: 1)
                background.isHidden = false
                self.layer?.backgroundColor = NSColor.clear.cgColor
                bottomLine.isHidden = false
                if like.image == #imageLiteral(resourceName: "Favorite_dark") {like.image = #imageLiteral(resourceName: "Favorite_outline")}
            }
        }
    }
    
    var previousThreads = 0
    
    @IBAction func like(_ sender: NSButton) {
        
        previousThreads += 1
        
        sender.image = sender.image == #imageLiteral(resourceName: "Favorite_outline") || sender.image == #imageLiteral(resourceName: "Favorite_dark") ? #imageLiteral(resourceName: "Favorite") : self.backgroundStyle == .dark ? #imageLiteral(resourceName: "Favorite_dark") : #imageLiteral(resourceName: "Favorite_outline")
        
        self.vc.shouldUpdateFavorites = false
        
        let favCell = vc.EATableView.view(atColumn: 0, row: 3, makeIfNecessary: false) as! EACellView
        if sender.image == #imageLiteral(resourceName: "Favorite") {
            favCell.digit += 1
            numberOfLikes.integerValue += 1
            if #available(OSX 10.12.2, *), self.backgroundStyle == .dark || EAname.stringValue == vc.EA_Name.stringValue {
                (self.vc.touchBar?.item(forIdentifier: NSTouchBarItem.Identifier(rawValue: "Button: Like"))?.view as? NSButton)?.image = #imageLiteral(resourceName: "Favorite_small")
            }
        } else {
            favCell.digit -= 1
            numberOfLikes.integerValue -= 1
            if #available(OSX 10.12.2, *), self.backgroundStyle == .dark || EAname.stringValue == vc.EA_Name.stringValue {
                (self.vc.touchBar?.item(forIdentifier: NSTouchBarItem.Identifier(rawValue: "Button: Like"))?.view as? NSButton)?.image = #imageLiteral(resourceName: "favorite_small_dark")
            }
        }
        
        if favCell.numberOfFavorites.integerValue <= 0 {
            favCell.numberOfFavorites.stringValue = ""
        }
        
        
        let url = URL(string: serverAddress + "tenicCore/FavoriteEA.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "EA=\(EAname.stringValue)&id=\(appstudentID)&like=\(sender.image == #imageLiteral(resourceName: "Favorite") ? 1 : 0)".data(using: .utf8)
                
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil || !String(data: data!, encoding: .utf8)!.contains("|") {
                Swift.print(error!)
                return
            }
            let s = String(data: data!, encoding: .utf8)!
            let number = Int(s.components(separatedBy: "|")[0]) ?? 0
            let userLikes = Int(s.components(separatedBy: "|")[1]) ?? 0
            DispatchQueue.main.async {
                self.previousThreads -= 1
                
                if (sender.image == #imageLiteral(resourceName: "Favorite_outline") || sender.image == #imageLiteral(resourceName: "Favorite_dark")) && self.vc.EATableView.selectedRow == 3 {
                    let index = self.vc.visibleEAs.map({$0.name}).index(of: self.EAname.stringValue)!
                    self.vc.EADetailTable.removeRows(at: IndexSet(integer: index), withAnimation: NSTableView.AnimationOptions.effectFade)
                    self.vc.responsive = false
                    self.vc.visibleEAs.remove(at: index)
                    self.vc.responsive = true
                }
                if self.previousThreads == 0 {
                    self.numberOfLikes.integerValue = number
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.vc.shouldUpdateFavorites = true
                    }
                }
                
                favCell.numberOfFavorites.stringValue = userLikes > 0 ? String(userLikes) : ""
            }
            
        }
        task.resume()
    }
}
