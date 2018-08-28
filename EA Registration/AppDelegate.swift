//
//  AppDelegate.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/3/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa
import OpenDirectory

// We will set some constants here.

let serverAddress = "http://47.52.6.204/" // This is our current server address

var appadvisory = "" // A global variable for the user's advisory, or email if the user is a teacher.
var appfullname = "" // The displayed name of the user.
var appstudentID = "" // The 10-digit ID of the user.
var isTeacher: Bool {
    if ["SSEA", "99999999"].contains(appstudentID) {return true}
    if appstudentID.characters.count < 8 {return false}
    
    if appstudentID.characters.count == 10 {return false}
    
    let year = String(Array(appstudentID.characters)[0...1])
    
    return year == "20"
} // Returns whether the user is a teacher. Note that this is a computed variable, so its value is determined by the value of appstudentID.

func isTeacher(_ id: String) -> Bool { // A function that determines whether a given ID is of a teacher or student
    
    if ["SSEA", "99999999"].contains(id) {return true}
    if id.characters.count < 8 {return false}
    
    if id.characters.count == 10 {return false}
    
    let year = String(Array(id.characters)[0...1])
    
    return year == "20"
}


let schoolWifi = ["BCIS WIFI", "BCIS INF"] // Used to identify whether users are on campus wifi.

let AESKey = "Tenic" // We encrypt media files using our own algorithm. This is the key. DO NOT change this entry.

var logged_in = false {
    // A couple of menu items need to be changed once the user logs in.
    didSet {
        let menu = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!
        menu.submenu?.item(withTitle: "Change Password")?.isEnabled = logged_in
        menu.submenu?.item(withTitle: "Open Messenger...")?.isEnabled = logged_in
        menu.submenu?.item(withTitle: "Log in...")?.isHidden = logged_in
        menu.submenu?.item(withTitle: "Log out...")?.isHidden = !logged_in
        menu.submenu?.item(withTitle: "Update Profile...")?.isEnabled = logged_in
        menu.submenu?.item(withTitle: "Update Identity...")?.isEnabled = logged_in
    }
}

func regularizeID(_ id: String) -> String? {
    if ["99999999", "SSEA"].contains(id) {
        return id
    } else if ![10,8].contains(id.characters.count) || Int(id) == nil || !["0", "1"].contains(String(id.characters.last!)) && id.characters.count != 8 {
        return nil
    } else if id.characters.count == 8 && !id.hasPrefix("20") {
        return "20" + id
    } else {
        return id
    }
}

@NSApplicationMain

class AppDelegate: NSObject, NSApplicationDelegate, NSURLDownloadDelegate, NSMenuDelegate {
    
    
    // This is the application delegate, which mainly deals with menu actions.
    
    var map_Window: NSWindow?
    @IBOutlet weak var lockscreen: NSView!
    @IBOutlet weak var installUpdate: NSMenuItem!
    @IBOutlet weak var updateItem: NSMenuItem!
    @IBOutlet weak var muteItem: NSMenuItem!
    
    var viewController: ViewController?
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true // After the user closes the last window, the app automatically quits.
    }
    
    func createSource() {
        /*
         This function is only available with my ID and the SSEA account. It allows you to create a new animation file from a png sequence. These files will be encrypted into Assets.tenic.
        */
        let panel = NSOpenPanel()
        panel.title = "Please select the file(s) to add:"
        panel.prompt = "Add"
        panel.showsHiddenFiles = true
        panel.treatsFilePackagesAsDirectories = true
        panel.allowsMultipleSelection = true
        
        if panel.runModal().rawValue == 1 {
        
            var data = [Data]()
        
            for i in panel.urls.map({$0.path}) {
                data.append(try! Data(contentsOf: URL(fileURLWithPath: i)))
            }
            let savepanel = NSSavePanel()
            savepanel.prompt = "Export"
            savepanel.nameFieldStringValue = "Name"
            savepanel.title = "Export"
            if savepanel.runModal().rawValue == 1 {
                NSKeyedArchiver.archiveRootObject(data, toFile: savepanel.url!.path)
            }
        }
        
    }
    
    
    // This is the lock function. The admin can lock a user's Find my EA application.
    
    func applicationWillBecomeActive(_ notification: Notification) {
        NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")?.submenu?.delegate = self
        let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
        var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
        if identity["Lock"] != nil {
            lock(identity["Lock"]!)
            identity.removeValue(forKey: "Lock")
            NSKeyedArchiver.archiveRootObject(identity, toFile: path.expandingTildeInPath)
        }
    }
    
    var unlockPassword = ""
    
    // The actual screen lock function is carried out
    
    func lock(_ password: String) {
        unlockPassword = password
        // Default: 0
        // Auto hide dock: 1
        // Hide dock: 2
        // Auto hide menu bar: 4
        // Hide menu bar: 8
        // Disable apple menu: 16
        // Diable process switching: 32
        // Disable force quit: 64
        // Disable session termination: 128
        // Disable hide application: 256
        // Disable menu bar transparency: 512
        // Fullscreen: 1024
        
        let options = NSApplication.PresentationOptions(rawValue: 2 + 8 + 16 + 32 + 128 + 256 + 64)
        let optionsDict = [NSView.FullScreenModeOptionKey.fullScreenModeApplicationPresentationOptions :
            NSNumber(value: options.rawValue as UInt)]
        lockscreen.enterFullScreenMode(NSScreen.main!, withOptions: optionsDict) // Locks the screen
    }
    
    // Pressing enter after finished with the correct password will unlock the screen
    @IBAction func unlock(_ sender: NSTextField) {
        if sender.stringValue == unlockPassword || sender.stringValue == "1234567890qwertyuiopasdfghjklzxcvbnm" { // I provided another key here just in case.
            lockscreen.exitFullScreenMode(options: nil)
        }
    }

    // Update package
    
    @IBAction func installUpdate(_ sender: NSMenuItem) {
        let command = Terminal(launchPath: "/usr/bin/open", arguments: [NSTemporaryDirectory() + "Find my EA.pkg"])
        command.execUntilExit()
        NSApplication.shared.terminate(0)
        sender.isEnabled = false
    }
    
    // The Whitelist function only appears when the user presses down the option key while clicking the main menu.
    
    func menuWillOpen(_ menu: NSMenu) {
        if menu.title == "Find my EA" {
            muteItem.state = NSControl.StateValue(rawValue: muted ? 1 : 0)
            let menuItem = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")?.submenu?.item(withTitle: "Whitelist")
            menuItem!.isHidden = !NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option)
        } else if menu.title == "Window" {
            menu.item(withTitle: "Find my EA")?.isHidden = !logged_in || (appWindow != nil && appWindow!.isVisible)
        }
    }
    
    func menu(_ menu: NSMenu, willHighlight item: NSMenuItem?) {
        if item?.title == "Install Update" {
            let attributes = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: NSColor(red: 1, green: 0.99, blue: 0.7, alpha: 1)]
            installUpdate.attributedTitle = NSAttributedString(string: installUpdate.title, attributes: attributes)
        } else {
            let attributes = [NSAttributedStringKey.font: NSFont.systemFont(ofSize: 14), NSAttributedStringKey.foregroundColor: NSColor(red: 1/255, green: 141/255, blue: 140/255, alpha:1)]
            installUpdate.attributedTitle = NSAttributedString(string: installUpdate.title, attributes: attributes)
        }
    }
    
    // Logout menu item
    
    @IBAction func logout(_ sender: NSMenuItem) {
        viewController?.logout(NSButton())
    }
    
    // Check for update menu item
    
    @IBAction func checkforUpdates(_ sender: NSMenuItem) {
        checkForUpdates(true)
        viewController?.updateProgressText.stringValue = "Checking for updates..."
    }
    
    // This function is responsible for opening the menu.
    
    @IBAction func openHistory(_ sender: NSMenuItem) {
        let string:NSString = "~/Library/Application Support/Find my EA/.history"
        let command = Terminal(launchPath: "/bin/mkdir", arguments: ["-p", string.expandingTildeInPath])
        command.execUntilExit()
        command.launchPath = "/usr/bin/open"
        command.arguments = [messengerPath]
        command.exec()
    }

    // Change color theme
    
    @IBAction func toggleColor(_ sender: NSMenuItem) {
        if sender.state.rawValue == 1 {
            sender.state = NSControl.StateValue(rawValue: 0)
        } else {
            sender.state = NSControl.StateValue(rawValue: 1)
        }
    }
    
    // Save the change if the user changed the color theme
    
    func applicationWillTerminate(_ aNotification: Notification) {
        let menu = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!
        UserDefaults.standard.set(menu.submenu?.item(withTitle: "Blue Theme")?.state.rawValue == 1, forKey: "Blue Theme")
    }
    
    @IBAction func findMyEA(_ sender: NSMenuItem) {
        appWindow?.makeKeyAndOrderFront(sender)
    }
    
    @IBAction func visitFacebook(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "https://www.facebook.com/teamtenic/")!)
    }
    
    @IBAction func visitWebsite(_ sender: NSMenuItem) {
        NSWorkspace.shared.open(URL(string: "http://tenic.xyz/")!)
    }
    
    @IBAction func toggleMuted(_ sender: NSMenuItem) {
        if sender.state.rawValue == 0 {
            muted = true
            sender.state = NSControl.StateValue(rawValue: 1)
        } else {
            muted = false
            sender.state = NSControl.StateValue(rawValue: 0)
        }
    }
    
    var muted: Bool {
        get {
            let path: NSString = "~/Library/Application Support/Find my EA/.mute"
            let fm = FileManager()
            return fm.fileExists(atPath: path.expandingTildeInPath)
        }
        set (newValue) {
            let path: NSString = "~/Library/Application Support/Find my EA/.mute"
            if !newValue {
                Terminal().deleteFileWithPath(path.expandingTildeInPath)
            } else {
                Terminal(launchPath: "/bin/mkdir", arguments: ["-p", path.expandingTildeInPath]).exec()
            }
        }
    }

}

class LockScreen: NSView {
    override var isOpaque: Bool {
        return false
    }
}

// Broadcast a message. This is a standard way to communicate with the Tenic server through Swift and PHP.

func broadcastMessage(_ title: String, message: String, filter: String, msgdate: String?) {
    
    // We need to generate a very accurate date (to prevent conincidence)
    
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "y/MM/dd HH:mm:ss:SSS"
    let date = formatter.string(from: Date())
    
    // The first step is to specify the PHP file to send.
    let url = URL(string: serverAddress + "tenicCore/SendMessage.php")
    
    // Next, instantiate an URLRequest, which is a specification of the task we want to perform
    var request = URLRequest(url: url!)
    
    // Use the POST method because we are uploading some data to the server
    request.httpMethod = "POST"
    
    // Here is the data we want to upload. We have the name of every variable, followed by an equal sign '=', and the value. You must make sure there are no special characters in them.
    let postString = "date=\(msgdate ?? date)&message=\([filter, title, message].joined(separator: "\u{2028}"))" // We use the \u{2028} as our separator between multiple components of a string
    
    // Now we set the body of our request to the prepared data
    request.httpBody = postString.data(using: String.Encoding.utf8)
    
    // Specify the actual URL task
    let task = URLSession.shared.dataTask(with: request) {
        data, response, error in // Three values are returned.
                
        // data: The constant that stores the information returned from the PHP script
        // response: We typically ignore that
        // error: If there has been an error, this value is non-nil and will unwrap and print it. Very useful for debugging.
        
        if error != nil {
            print("error=\(error!)") // The user doesn't care whether there is an error. The worst case is that the message is not sent.
        }
        return
    }
    
    // The code above only specifies the task. Now we let it start running.
    task.resume()
}


// This extension fixes a bug in the original IT-Switch class. DO NOT REMOVE.

extension ITSwitch {
    override open var canBecomeKeyView: Bool {
        return false
    }
    
}
