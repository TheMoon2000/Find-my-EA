//
//  StartupView.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/4/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

let defaultColor = NSColor(red: 38.0/255, green: 130.0/255, blue: 250.0/255, alpha: 0.1)
//let highlightColor = NSColor(red: 30/255, green: 120/255, blue: 248/255, alpha: 1)
//let mouseDownColor = NSColor(red: 25/255, green: 115/255, blue: 245/255, alpha: 1)
let highlightColor = NSColor(red: 38.0/255, green: 130.0/255, blue: 250.0/255, alpha: 0.2)
let mouseDownColor = NSColor(red: 38.0/255, green: 130.0/255, blue: 250.0/255, alpha: 0.15)


var isOutside = true

class StartupView: NSView, NSTextFieldDelegate {

    @IBOutlet weak var beginButton: NSButton!
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var advisory: NSTextField!
    @IBOutlet weak var id: NSTextField!
    @IBOutlet weak var wechat: NSTextField!
    
    let d = NSUserDefaults.standardUserDefaults()
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
    }
    
    
    override func awakeFromNib() {
        
        beginButton.wantsLayer = true
        beginButton.layer?.backgroundColor = defaultColor.CGColor
        
        beginButton.layer?.cornerRadius = 22
        beginButton.layer?.borderColor = NSColor.whiteColor().CGColor
        beginButton.layer?.borderWidth = 1
        
        let pstyle = NSMutableParagraphStyle()
        pstyle.alignment = .Center
        
//        let buttonFont = NSFont(name: "Helvetica Neue", size: 18)
        
//        beginButton.attributedTitle = NSAttributedString(string: "Let's Begin", attributes: [NSForegroundColorAttributeName: NSColor.whiteColor(), NSParagraphStyleAttributeName: pstyle, NSFontAttributeName: buttonFont!])
        
        advisory.stringValue = d.stringForKey("Advisory") ?? ""
        
        name.stringValue = d.stringForKey("Name") ?? ""
        
        id.stringValue = d.stringForKey("ID") ?? ""
        
        wechat.stringValue = d.stringForKey("Wechat") ?? ""
        
        beginButton.addTrackingArea(NSTrackingArea(rect: beginButton.bounds, options: NSTrackingAreaOptions(rawValue: 129), owner: self, userInfo: nil))
        
        window?.standardWindowButton(.ZoomButton)?.hidden = true
        window?.standardWindowButton(.MiniaturizeButton)?.hidden = true
//        window?.standardWindowButton(.CloseButton)!.wantsLayer = true
        
//        let filter = CIFilter(name: "CIColorPolynomial", withInputParameters: [
//            "inputRedCoefficients": CIVector(CGRect: CGRectMake(0, 1, 0, 0)),
//            "inputGreenCoefficients": CIVector(CGRect: CGRectMake(0.4,1,0,0)),
//            "inputBlueCoefficients": CIVector(CGRect: CGRectMake(0.5,1,0,0)),
//            "inputAlphaCoefficients": CIVector(CGRect: CGRectMake(0.1,1,0,0))
//            ])
//        let filter = CIFilter(name: "CIGaussianBlur", withInputParameters: ["inputRadius": 2])
//        window?.standardWindowButton(.CloseButton)?.layer?.filters?.append(filter!)
        
        
        
        let font = NSFont(name: "Helvetica Neue Light", size: 25)!
        let placeholderColor = NSColor(white: 0.9, alpha: 0.2)
        
        
        for i in [name, advisory, id, wechat] {
            let attrStr = NSMutableAttributedString(string: i.placeholderString!)
            attrStr.addAttribute(NSForegroundColorAttributeName, value: placeholderColor, range: NSMakeRange(0, attrStr.length))
            attrStr.addAttribute(NSFontAttributeName, value: font, range: NSMakeRange(0, attrStr.length))
            
            i.placeholderAttributedString = attrStr
        }



    }
    
    override func controlTextDidChange(obj: NSNotification) {
        
//        a.setAttributedString(a as! NSAttributedString)
        if obj.object! as! NSTextField == name {
            name.wantsLayer = true
            name.layer?.borderWidth = 0
        }
        else if obj.object! as! NSTextField == advisory {
            advisory.wantsLayer = true
            advisory.layer?.borderWidth = 0
        }
        else if obj.object! as! NSTextField == id {
            id.wantsLayer = true
            if id.stringValue.characters.count == 8 {
                id.layer?.borderWidth = 0
            }
        }
    }
    
    override func mouseEntered(theEvent: NSEvent) {
        isOutside = false
        beginButton.layer?.backgroundColor = highlightColor.CGColor
    }
    
    override func mouseExited(theEvent: NSEvent) {
        isOutside = true
        beginButton.layer?.backgroundColor = defaultColor.CGColor
    }
    
    @IBAction func begin(sender: NSButton) {
        var pass = true
        if name.stringValue == "" {
            name.wantsLayer = true
            name.layer?.borderWidth = 1
            name.layer?.borderColor = NSColor.redColor().CGColor
            pass = false
        }
        
        if advisory.stringValue == "" {
            advisory.wantsLayer = true
            advisory.layer?.borderWidth = 1
            advisory.layer?.borderColor = NSColor.redColor().CGColor
            pass = false
        }
        
        if id.stringValue.characters.count != 8 {
            id.wantsLayer = true
            id.layer?.borderWidth = 1
            id.layer?.borderColor = NSColor.redColor().CGColor
            pass = false
        }
        
        if !pass {return}
        
        d.setValue(name.stringValue, forKey: "Name")
        d.setValue(advisory.stringValue.uppercaseString, forKey: "Advisory")
        d.setValue(id.stringValue.uppercaseString, forKey: "ID")
        d.setValue(wechat.stringValue, forKey: "Wechat")
        newUserRegistration(name.stringValue, advisory: advisory.stringValue, id: id.stringValue, wechat: wechat.stringValue)
        let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate
        let vc = appDelegate.viewController
        vc!.letsbegin(beginButton)
        
        var identity = [String:String]()
        identity["Name"] = name.stringValue
        identity["Advisory"] = advisory.stringValue
        identity["ID"] = id.stringValue
//        identity["Wechat"] = wechat.stringValue
        
        let string:NSString = "~/Library/Application Support/Find my EA"
        let command = Terminal(launchPath: "/bin/mkdir", arguments: ["-p", string.stringByExpandingTildeInPath])
        command.execUntilExit()
        command.launchPath = "/usr/bin/chflags"
        command.arguments = ["hidden", string.stringByExpandingTildeInPath]
        command.exec()
        
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        NSKeyedArchiver.archiveRootObject(identity, toFile: path.stringByExpandingTildeInPath)
    }
    
}

func newUserRegistration(name: String, advisory: String, id: String, wechat: String) {
    let url = NSURL(string: "http://59.110.7.144/PHP/NewUser.php")!
    let request = NSMutableURLRequest(URL: url)
    request.HTTPMethod = "POST"
    let postString = "name=\(name)&advisory=\(advisory)&id=\(id)&wechat=\(wechat)&computer=\(NSHost.currentHost().name!)"
    var hasRun = false
    request.HTTPBody = postString.dataUsingEncoding(NSUTF8StringEncoding)
    let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
        data, response, error in
        if hasRun {return}
        if error != nil {
            print("error=\(error)")
        }
        do {
            print(String(data: data!, encoding: NSUTF8StringEncoding)!)
            let json = try NSJSONSerialization.JSONObjectWithData(data!, options: .MutableContainers) as! NSDictionary
            if json["status"] as! String == "maintenance" {
                dispatch_async(dispatch_get_main_queue(), {
                    let alert = NSAlert()
                    alert.messageText = json["title"] as! String
                    alert.informativeText = json["message"] as! String
                    alert.addButtonWithTitle("Quit").keyEquivalent = "\r"
                    alert.window.title = "Find my EA"
                    alert.alertStyle = .CriticalAlertStyle
                    if alert.runModal() == NSAlertFirstButtonReturn {
                        NSApplication.sharedApplication().terminate(nil)
                    }
                })
            }
        } catch let err as NSError {
            print(err)
        }
        hasRun = true
    }
    task.resume()
}

class beginButton: NSButton {
    override func mouseDown(theEvent: NSEvent) {
        self.layer?.backgroundColor = mouseDownColor.CGColor
    }
    
    override func mouseUp(theEvent: NSEvent) {
        if !isOutside {
            self.layer?.backgroundColor = highlightColor.CGColor
            super.mouseDown(theEvent)
        }
    }
}
