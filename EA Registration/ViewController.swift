//
//  ViewController.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/3/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa
import CoreWLAN

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

// Set some convenient touchbar constants here..

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBarItem.Identifier {
    static let tenicLabel = NSTouchBarItem.Identifier(rawValue: "Tenic Touch Bar Label Item")
    static let joinButton = NSTouchBarItem.Identifier(rawValue: "Touch Bar Join Button")
    static let mainView = NSTouchBarItem.Identifier(rawValue: "Main Scroll View")
}

@available(OSX 10.12.2, *)
fileprivate extension NSTouchBar.CustomizationIdentifier {
    static let tenicBar = NSTouchBar.CustomizationIdentifier(rawValue: "Tenic Touch Bar")
}

let loading_delay = 1.05 // How long the user would see the animation

var hasRunAlert = false

// The purpose of this function is very obvious from its name. We need to calculate the height of the font in order to adjust the height of alert window.

func calculateHeightForFont(_ font: NSFont, text: String, width: CGFloat, label: Bool) -> CGFloat {
    let textfield = AutoResizingTextField()
    textfield.frame = NSMakeRect(0,0, width, 22)
    textfield.font = font
    textfield.stringValue = text
    if label {
        textfield.isBordered = false
        textfield.isBezeled = false
    }
    return textfield.intrinsicContentSize.height
}


var messengerPath: String {
    let rawPath: NSString = "~/Library/Containers/com.tenic.EA-Center/"
    let absolutePath = rawPath.expandingTildeInPath
    let appPath = absolutePath + "/EA Center Messenger.app"
    
    return appPath
}

let animationPack = NSKeyedUnarchiver.unarchiveObject(withFile: Bundle.main.path(forResource: "Assets", ofType: "tenic")!) as! [String: Data] // Read the Assets.tenic file

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, WindowResizeDelegate, NSSearchFieldDelegate, NSTextFieldDelegate, NSURLDownloadDelegate, NSMenuDelegate, NSSplitViewDelegate, GRRequestsManagerDelegate, NSTouchBarDelegate {

    
    var VIP = [String:String]()
  
    @IBOutlet weak var EATableView: NSTableView!
    @IBOutlet weak var EADetailTable: NSTableView!
    @IBOutlet weak var EA_Groups: NSTextField!
    @IBOutlet weak var sortBy: NSTextField!
    @IBOutlet weak var sortCriterion: NSPopUpButton!
    @IBOutlet weak var posterLoadingLabel: NSTextField!
    
    @IBOutlet weak var creditsTitle: NSTextField!
    @IBOutlet weak var creditsTop: NSTextField!
    @IBOutlet weak var creditsBottom: NSTextField!
    @IBOutlet weak var bigLogoImage: NSImageView!
    
    @IBOutlet weak var noResults: NSTextField!
    @IBOutlet weak var loadImage: LoadImage!
    
    @IBOutlet weak var mainView: NSView!
    @IBOutlet weak var splitviewLeft: NSVisualEffectView!
    @IBOutlet weak var splitviewMiddle: NSView!
    @IBOutlet weak var splitviewRight: NSView!
    @IBOutlet weak var splitView: NSSplitView!
    @IBOutlet weak var topBanner: NSView!
    @IBOutlet weak var bottomBar: NSView!
    @IBOutlet weak var bottomInfoLabel: NSTextField!
    
    @IBOutlet weak var EA_Name: NSTextField!
    @IBOutlet weak var signupLabel: NSTextField!
    @IBOutlet weak var signupButton: NSButton!
    @IBOutlet weak var signupSpinner: NSProgressIndicator!
    @IBOutlet weak var downloadImage: LoadImage!
    @IBOutlet var message: NSTextView!
    @IBOutlet var hiddenMessage: NSTextView!
    @IBOutlet weak var messageScrollView: NSScrollView!
    @IBOutlet weak var percentage: NSTextField!
    @IBOutlet weak var colorCodes: ColorGroups!
    @IBOutlet weak var enableColors: ITSwitch!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var updateProgressText: NSTextField!
    
    @IBOutlet weak var updateDownloadProgress: Progress!
    @IBOutlet weak var logoImage: DraggableImage!
    @IBOutlet weak var updatePercentage: NSTextField!
    @IBOutlet weak var updateDownloadBackground: NSView!
    @IBOutlet weak var reloadButton: NSButton!
    @IBOutlet weak var logoutButton: NSButton!
    @IBOutlet weak var loginStatus: NSTextField!
    
    var currentFilterColor = "_"
    
//    @IBOutlet weak var middleCollapseButton: NSButton!
    
    @IBOutlet weak var zoomButton: NSButton! // The custom fullscreen button
    
    var userEAStatus = [String:String]()
    
    var downloadQueue = [String: (download: NSURLDownload, total: Int, downloaded: Int)]() // The user may choose to download multiple EA posters at once. Therefore, we need an array to store these download instances.
    
//    var removedRows = NSMutableIndexSet()
    
    //The little grey banner with the signup sign
    @IBOutlet weak var signupBackground: NSView!
    
    let d = UserDefaults.standard // A shortcut for accessing ~/Library/Preferences/[App ID Plist name]
    
    //For deletion animation
    var signupEA_Name = ""
    
    // For ignoring one of the table view datasource methods during app launch
    var initialization = false
    
    var firstLogin = true
    
    // Right Click. We use this variable to communicate the current right-clicked row in EADetailTable between multiple functions.
    var rightclickRowIndex = -1
    
    // This is the central variable that stores all the EAs loaded from the server.
    var EAs = ["All EAs": [EA](), "EAs Pending": [EA](), "EAs I Joined": [EA](), "Favorites": [EA]()]
    {
        didSet {
            if responsive {
                let allCell = self.EATableView.view(atColumn: 0, row: 0, makeIfNecessary: false) as? EACellView
                allCell?.digit = EAs["All EAs"]!.count
        
                let pendingCell = self.EATableView.view(atColumn: 0, row: 1, makeIfNecessary: false) as? EACellView
                pendingCell?.digit = self.EAs["EAs Pending"]!.count
                
                let joinedCell = self.EATableView.view(atColumn: 0, row: 2, makeIfNecessary: false) as? EACellView
                joinedCell?.digit = self.EAs["EAs I Joined"]!.count
            }
        }
    } // A masterlist of all the EAs and the three filter categories

    
    let EACategories = ["All EAs", "EAs Pending", "EAs I Joined", "Favorites"] // A shortcut for the names of the rows
    
    var responsive = true // Whether the table should reload when the data for EAs changes.
    
    // This is about how the table should animate when it updates
    var visibleEAs = [EA]() {
        
        // 'willSet' specifies actions to be taken before the new value is assigned to visibleEAs.
        willSet (newValue) {
            if !responsive {return} // Sometimes we don't want the code below to be run, so we set responsive to false to skip them.
            
            // The new value is 0, but the old value is not 0, then we do a fade animation to remove all rows.
            if newValue.count == 0 && visibleEAs.count != 0 {
                EADetailTable.removeRows(at: IndexSet(integersIn: NSMakeRange(0, EADetailTable.numberOfRows).toRange()!), withAnimation: NSTableView.AnimationOptions.effectFade)
            } else {
                // If this does not happen, then it's hard to design an animation, so we don't perform any.
                EADetailTable.removeRows(at: IndexSet(integersIn: NSMakeRange(0, EADetailTable.numberOfRows).toRange()!), withAnimation: NSTableView.AnimationOptions())
            }
        }
        
        // 'didSet' specifies actions to be done after the new value is assigned to visibleEAs.
        didSet (oldValue) {
            
            // Of course, there is no point of sorting if there is no EA to sort.
            sortBy.isEnabled = visibleEAs.count > 0
            sortCriterion.isEnabled = sortBy.isEnabled
            
            noResults.isHidden = visibleEAs.count != 0 // Depending on whether there is any EA on the server, we choose to show or hide the sign that says there is no EA.
            
            if !responsive {return} // Again, allow occasions when no action should be taken.
            if EATableView.selectedRow != 0 {
                responsive = false
                visibleEAs = sortEAs(visibleEAs) // We first sort without triggering anything else
                responsive = true
            }

            // This means visibleEAs used to have 0 elements, but not anymore.
            if visibleEAs.count != oldValue.count && oldValue.count == 0 {
                
                // In this case, we are safe to use an animation to reveal all the rows
                EADetailTable.insertRows(at: IndexSet(integersIn: NSMakeRange(0, visibleEAs.count).toRange()!), withAnimation: NSTableView.AnimationOptions.effectFade)
            } else {
                // Otherwise, it's difficult to design a nice animation, so we don't perform one.
                EADetailTable.insertRows(at: IndexSet(integersIn: NSMakeRange(0, visibleEAs.count).toRange()!), withAnimation: NSTableView.AnimationOptions())
            }
            
            // We disable the color code view temporarily during a refresh.
            colorCodes.enabled = true
            
            // This function refreshes the contents of the current touchbar (new mac models only).
            if #available(OSX 10.12.2, *) {
                self.touchBar = self.makeTouchBar()
            }
        }
    }
    
    // This function runs before the user sees the view
    override func viewDidLoad() {
        super.viewDidLoad()
        
        shell("/bin/sh", arguments: ["-c", "open '\(messengerPath)'"]) // Launch the background messenger app
        
        enableColors.checked = d.bool(forKey: "Color Code") // Read user settings on category colors
        
        
        // Set the view controller to a variable in the App Delegate, making it easier to reference later
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        appDelegate.viewController = self
        
        // The following four lines of code will add a right-click menu to the EA detail table view
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(withTitle: "Reload", action: nil, keyEquivalent: "")
        EADetailTable.menu = menu
        
        splitView.delegate = self
        
        // Register the interface files for the two table views
        let nib = NSNib(nibNamed: NSNib.Name(rawValue: "EACellView"), bundle: Bundle.main)
        EATableView.register(nib, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EA Category View"))
        
        let infoNib = NSNib(nibNamed: NSNib.Name(rawValue: "EAInfo"), bundle: Bundle.main)
        EADetailTable.register(infoNib, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EA Info"))
        
        signupBackground.isHidden = true
        signupBackground.wantsLayer = true
        splitviewMiddle.wantsLayer = true
        topBanner.wantsLayer = true
        splitviewRight.wantsLayer = true
        
        let string: NSString = "~/Library/Preferences/com.apple.universalaccess.plist"
        let i = NSDictionary(contentsOfFile: string.expandingTildeInPath)!["reduceTransparency"] as? CGFloat ?? 0

        object_setClass(splitviewLeft, VibrantView.self)
        splitviewLeft.material = .light
                
        // Originally, we designed 2 color themes, red and blue. However, blue seems to be more aesthetically pleasing, so we stick with it for default. However, the other color theme is still available, and we set the appearance during initialization.
        if d.bool(forKey: "Blue Theme") {
            splitviewLeft.alphaValue = 1 - i

            signupBackground.layer?.backgroundColor = NSColor(red: 210/255, green: 233/255, blue: 253/255, alpha: 0.94).cgColor
            splitviewMiddle.layer?.backgroundColor = NSColor(red: 235/255, green: 245/255, blue: 255/255, alpha: 1).cgColor
            splitviewRight.layer?.backgroundColor = NSColor(red: 245/255, green: 250/255, blue: 255/255, alpha: 1).cgColor
            logoImage.image = #imageLiteral(resourceName: "mainlogo_blue")
            enableColors.tintColor = NSColor(red: 63/255, green: 161/255, blue: 232/255, alpha: 1)
        } else {
            signupBackground.layer?.backgroundColor = NSColor(red: 255/255, green: 205/255, blue: 204/255, alpha: 0.9).cgColor
            splitviewMiddle.layer?.backgroundColor = NSColor(red: 255/255, green: 250/255, blue: 250/255, alpha: 1).cgColor
            splitviewRight.layer?.backgroundColor = NSColor(red: 255/255, green: 253/255, blue: 253/255, alpha: 1).cgColor
            logoImage.image = #imageLiteral(resourceName: "mainlogo")
            for i in [creditsTitle, creditsTop, creditsBottom] {
                i?.textColor = NSColor(red: 0.9, green: 0.5, blue: 0.45, alpha: 0.7)
            }
            enableColors.tintColor = NSColor(red: 210/255, green: 41/255, blue: 33/255, alpha: 1)
        }
        
        bigLogoImage.image = logoImage.image
        
        loadFromServer(0) // This function fetches data from the server
        launchDaemon() // This function launches Find my EA Messenger
        
        if appstudentID == "" {
            loginStatus.stringValue = "Loggin in..."
            DispatchQueue.main.async {
                self.bgAuth()
            }
            
        } // This function authenticates the user in background
        
        
        messageScrollView.isHidden = true
        
        updateDownloadBackground.wantsLayer = true
        updateDownloadBackground.layer!.cornerRadius = updateDownloadBackground.frame.width / 2
        updateDownloadBackground.layer!.backgroundColor = NSColor(white: 1, alpha: 0.1).cgColor
        updateDownloadBackground.layer!.isHidden = true

        // This function obtains the user's settings on the sorting criterion.
        if d.integer(forKey: "Order") == 0 {
            sortCriterion.title = "Popularity"
        } else if d.integer(forKey: "Order") == 1 {
            sortCriterion.title = "Alphabetical Order"
        } else {
            sortCriterion.title = "# of Participants"
        }
        
        // Two seconds later, we trigger the auto-update check. The delay makes the app more user-friendly because you probably don't want an update to pop out the moment you logged in.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            checkForUpdates(false)
        }
    }
    
    // These functions are run AFTER the window is loaded.
    override func viewDidAppear() {
        bottomBar.wantsLayer = true
        if d.bool(forKey: "Blue Theme") {
            bottomBar.layer?.backgroundColor = NSColor(red: 5/255, green: 120/255, blue: 180/255, alpha: 1).cgColor
        } else {
            bottomBar.layer?.backgroundColor = NSColor(red: 20/255, green: 20/255, blue: 20/255, alpha: 1).cgColor
        }
        if !initialization {bottomInfoLabel.stringValue = "Loading..."}
        
        if ["2010127051", "SSEA", "99999999"].contains(appstudentID) {
            let menu = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!.submenu!
            menu.addItem(withTitle: "Create Source Item", action: Selector(("createSource")), keyEquivalent: "")
        }
        
        favoriteUpdate() // Begin the background refresh for the number of likes for each EA.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.19) {
            self.view.window?.makeKeyAndOrderFront(nil)
        }
    }
    
    // We clear all the cache on exit.
    override func viewDidDisappear() {
        for i in EAs["All EAs"]! {
            Terminal().deleteFileWithPath(NSTemporaryDirectory() + i.name + ".rtfd")
        }
        Terminal().deleteFileWithPath(NSTemporaryDirectory() + "Description.rtfd")
    }
    
    // Background Authentication
        
    func bgAuth() {
        
        // Some setup
        
        if d.string(forKey: "ID") == nil || regularizeID(d.string(forKey: "ID")!) == nil || d.value(forKey: "Password") as? Data == nil {
            DispatchQueue.main.async {
                logged_in = false
                self.logout(self.logoutButton)
            }
        }
        let loginID = regularizeID(d.string(forKey: "ID")!)!
        let passdata = d.value(forKey: "Password") as! Data
        let loginPassword = String(data: passdata, encoding: String.Encoding.utf8)!
        
        let currentMAC = shell("/usr/sbin/networksetup", arguments: ["-getmacaddress", "wi-fi"]).components(separatedBy: " ")[2]
        
        // Remote connection
        
        let url = URL(string: serverAddress + "tenicCore/UserAuthentication.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let postString = "username=\(loginID)&password=\(loginPassword.encodedString)&hostname=\(Host.current().name!)&mac=\(currentMAC)&version=\(appversion)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, reponse, error in
            if error != nil || data == nil {
                // Some connection failure.
                DispatchQueue.main.async {
                    self.loginStatus.stringValue = "Not logged in."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {self.bgAuth()}
                }
                return
            } else {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary as? [String:String] ?? [String:String]()
                    
                    if json["status"] == "success" {
                        
                        DispatchQueue.main.async {
                            
                            let userInfo = json["message"]!.components(separatedBy: "|")
                            appstudentID = userInfo[0]
                            appfullname = userInfo[1]
                            appadvisory = userInfo[2]
                            logged_in = true
                           
                            self.enableLoginFeatures()
                            
                            let block = {
                                let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
                                var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
                                identity["ID"] = appstudentID
                                identity["Advisory"] = appadvisory
                                identity["Name"] = appfullname
                                NSKeyedArchiver.archiveRootObject(identity, toFile: path.expandingTildeInPath)
                            }
                            /*
                            if currentMAC != userInfo[3] && userInfo[3] != "" && userInfo[3] != "bogon" {
                                let alert = NSAlert()
                                alert.messageText = "Suspicious Activity Detected"
                                alert.alertStyle = .critical
                                let hostname = userInfo[4].components(separatedBy: ".")[0]
                                alert.informativeText = "Looks like your account has been used to log in to Found my EA from a different computer(\(hostname == "" ? "unknown" : hostname)). If that's not you, we strongly recommend you to change your password."
                                alert.addButton(withTitle: "I Understand").keyEquivalent = "\r"
                                alert.beginSheetModal(for: self.view.window!) {response in
                                    block()
                                }
                            } else {
                                block()
                            }
                            */
                            block()
                            for i in 0...3 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(i)) {
                                    if i == 3 {
                                        self.loginStatus.stringValue = ""
                                    } else {
                                        let noun = i == 3 ? "second" : "seconds"
                                        self.loginStatus.stringValue = "Successfully logged in. Dismissing in \(3 - i) " + noun + "."
                                    }
                                }
                            }
                        }
                    } else {
                        // This is simply not a valid account. Log out straightaway.
                        DispatchQueue.main.async {
                            self.logout(self.logoutButton)
                        }
                    }
                } catch {
                    // For some reason, no data is loaded. We suspect there is a connection failure.
                    DispatchQueue.main.async {
                        self.loginStatus.stringValue = "Not logged in."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {self.bgAuth()}
                    }
                }
            }
        }
        task.resume()
    }
    
    func enableLoginFeatures() {
        for i in 0..<EADetailTable.numberOfRows {
            let cell = EADetailTable.view(atColumn: 0, row: i, makeIfNecessary: false) as? EAInfo
            cell?.like.isEnabled = true
        }
        
        self.favoriteUpdate()
        
        if #available(OSX 10.12.2, *) {
            (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.isEnabled = true
        }
        
        if !signupBackground.isHidden {
            signupLabel.stringValue = "Updating EA's information..."
            signupSpinner.startAnimation(nil)
            signupButton.isHidden = true
            EAList("update")
        }
    }
    
    // Touch bar
    @available(OSX 10.12.2, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.customizationIdentifier = .tenicBar
        if loadImage.isAnimating {
            touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, .tenicLabel, NSTouchBarItem.Identifier.flexibleSpace]
        } else {
            let label = NSTouchBarItem.Identifier(rawValue: "Label: \(EACategories[EATableView.selectedRow]): ")
            if visibleEAs.count == 0 {
                touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, .mainView, NSTouchBarItem.Identifier.flexibleSpace]
            } else {
                touchBar.defaultItemIdentifiers = [label, .mainView]
            }
        }
//        touchBar.customizationAllowedItemIdentifiers = [.tenicLabel]
        return touchBar
    }
    
    // This function returns a touchbar item when the identifier is given.
    @available(OSX 10.12.2, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        
        switch identifier {
        case NSTouchBarItem.Identifier.tenicLabel:
            let item = NSCustomTouchBarItem(identifier: identifier)
            
            item.view = NSTextField(labelWithString: "Loading...")
            
            return item

        default:
            if identifier.rawValue.hasPrefix("EA: ") {
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.view = NSButton(title: item.identifier.rawValue.components(separatedBy: "EA: ")[1], target: self, action: #selector(ViewController.selectedEA(_:)))
                return item
            } else if identifier.rawValue.hasPrefix("Label: ") {
                let item = NSCustomTouchBarItem(identifier: identifier)
                
                item.view = NSTextField(labelWithString: identifier.rawValue.components(separatedBy: "Label: ")[1])
                
                return item
            } else if identifier.rawValue.hasPrefix("Button: ") {
                let item = NSCustomTouchBarItem(identifier: identifier)
                let title = identifier.rawValue.components(separatedBy: "Button: ")[1]
                if title == "Back" {
                    item.view = NSButton(title: "Back", target: self, action: #selector(ViewController.empty))
                    return item
                } else if title == "Cancel" {
                    item.view = NSButton(title: title, target: self, action: #selector(ViewController.signUp(_:)))
                    (item.view as! NSButton).bezelColor = NSColor(red: 1, green: 0.2, blue: 0.2, alpha: 1)
                } else if title == "Like" {
                    // guard
                    if EAs["All EAs"]!.filter({item -> Bool in
                        return item.name == EA_Name.stringValue
                    }).count == 0 {return nil}
                    
                    let theEA = EAs["All EAs"]!.filter({item -> Bool in
                        return item.name == EA_Name.stringValue
                    })[0]
                    
                    let imageToSet = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
                    
                    let button = NSButton(image: imageToSet, target: self, action: #selector(ViewController.toggleFavorite(_:)))
                    
                    button.isEnabled = appstudentID != ""
                    
                    item.view = button
                } else {
                    let button = NSButton(title: title, target: self, action: #selector(ViewController.signUp(_:)))
                    button.bezelColor = selectionLightBlueColor
                    button.isEnabled = appstudentID != ""
                    item.view = button
                }
                return item
            } else if identifier == .mainView {
                let scrollView = NSScrollView()
                let contentView = NSView()
                var x: CGFloat = 0
                
                // If there is nothing to show
                if visibleEAs.count == 0 {
                    let item = NSCustomTouchBarItem(identifier: identifier)
                    
                    item.view = NSTextField(labelWithString: "No results.")
                    
                    return item
                }
                
                for i in visibleEAs {
                    let button = NSButton(title: i.name, target: self, action: #selector(ViewController.selectedEA(_:)))
                    button.frame.size.height = 30
                    button.frame.origin = NSMakePoint(x, 0)
                    switch i.color {
                    case "Blue":
                        button.bezelColor = NSColor(red: 5/255, green: 130/255, blue: 185/255, alpha: 1)
                    case "Orange":
                        button.bezelColor = NSColor(red: 250/255, green: 189/255, blue: 40/255, alpha: 1)
                    case "Yellow":
                        button.bezelColor = NSColor(red: 1, green: 247/255, blue: 23/255, alpha: 1)
                    case "Green":
                        button.bezelColor = NSColor(red: 65/255, green: 225/255, blue: 65/255, alpha: 1)
                    case "Red":
                        button.bezelColor = NSColor(red: 255/255, green: 132/255, blue: 132/255, alpha: 1)
                    case "Pink":
                        button.bezelColor = NSColor(red: 237/255, green: 136/255, blue: 242/255, alpha: 1)
                    case "Purple":
                        button.bezelColor = NSColor(red: 166/255, green: 117/255, blue: 242/255, alpha: 1)
                    default: break
                    }
                    button.isEnabled = i.approval == "Approved"
                    contentView.addSubview(button)
                    x += button.frame.width + 8
                }
                contentView.frame.size = NSMakeSize(x, 30)
                scrollView.documentView = contentView
                let item = NSCustomTouchBarItem(identifier: identifier)
                item.view = scrollView
                return item
            }
            return nil
        }
        
    }
    
    // This is a touchbar function, and the sender if the touchbar button. If the user likes or un-likes an EA, they've got to select it first. We retrieve the user's selection, and we change the favorite status of that particular EA for the user.
    @objc func toggleFavorite(_ sender: NSButton) {
        var row = EADetailTable.selectedRow
        if row == -1 && EA_Name.stringValue != "" && visibleEAs.count == EADetailTable.numberOfRows {
            row = visibleEAs.map {$0.name} .index(of: EA_Name.stringValue) ?? -1
        }
        if let rowcell = EADetailTable.view(atColumn: 0, row: row, makeIfNecessary: false) as? EAInfo {
            rowcell.like(rowcell.like)
        }
    }
    
    // Another touchbar function. The sender is one of the colorful buttons that indicate each EA. The corresponding EA will be selected when the user presses on that EA button.
    @objc func selectedEA(_ sender: NSButton) {
        let eas = visibleEAs.map {$0.name}
        if let position = eas.index(of: sender.title) {
            colorCodes.isHidden = true
            self.tableView(EADetailTable, shouldSelectRow: position)
            EADetailTable.selectRowIndexes(IndexSet(integer: position), byExtendingSelection: false)
            let cell = EADetailTable.view(atColumn: 0, row: position, makeIfNecessary: true) as? EAInfo
            cell?.backgroundStyle = .dark
            EADetailTable.scrollRowToVisible(position) // Important. If the row to be selected is not currently visible, scroll so that it is visible.
            
            // By default, after the user makes the selection, we display 'loading...' as the touchbar sign.
            if #available(OSX 10.12.2, *) {
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, .tenicLabel, NSTouchBarItem.Identifier.flexibleSpace]
            } else {
                // Fallback on earlier versions
            }
        }
    }
    
    func sortEAs(_ eaList: [EA]) -> [EA] {
        var sorted = [EA]()
        if self.sortCriterion.title == "# of Participants" {
            sorted = eaList.sorted {first, second in
                if first.participants == second.participants {
                    return first.name.lowercased() < second.name.lowercased()
                } else {
                    return first.participants > second.participants
                }
            }
        } else if sortCriterion.title == "Alphabetical Order" {
            sorted = eaList.sorted {first, second in
                return first.name.lowercased() < second.name.lowercased() // One order is sufficient
            }
        } else if sortCriterion.title == "Popularity" {
            
            // First order: number of favorites
            // Second order: alphabetical order
            
            sorted = eaList.sorted {first, second in
                let firstcount = first.favorites == "" ? 0 : first.favorites.components(separatedBy: " | ").count
                let secondcount = second.favorites == "" ? 0 : second.favorites.components(separatedBy: " | ").count
                if firstcount == secondcount {
                    return first.name.lowercased() < second.name.lowercased()
                } else {
                    return firstcount > secondcount
                }
            }
        }
        return sorted
    }
    
    // An advanced search function that returns the EAs that pass a given keyword
    func filterEAs(_ eas: [EA], keyword: String, filter: String) -> [EA] {
        var tmp = [EA]()
        if keyword != "" {
            tmp = eas.filter({(myEA) -> Bool in
                let range = NSString(string: myEA.name).range(of: keyword, options: .caseInsensitive)
                let range2 = NSString(string: myEA.description).range(of: keyword, options: .caseInsensitive)
                let range3 = NSString(string: myEA.time).range(of: keyword, options: .caseInsensitive)
                
                return (range.location != NSNotFound) || range2.location != NSNotFound || range3.location != NSNotFound
            }).filter({filter == "_" || $0.color == filter})
        } else {
            return eas
        }
        return sortEAs(tmp)
    }
    
    // Global variables needed for layout during window resizing
    var constraint = [NSLayoutConstraint]()
    var constraint2 = [NSLayoutConstraint]()
    
    // This is our big secret, the FTP account.
    let requestManager = GRRequestsManager(hostname: "47.52.6.204:23333", user: "eamanager", password: "Tenic@EA")
    
    func openMap() {
        let ap = NSApplication.shared.delegate as! AppDelegate
        if ap.map_Window == nil {
            self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "openMap"), sender: self)
        } else {
            ap.map_Window?.makeKeyAndOrderFront(self)
        }
    }
    
    // Temporarily activate the width constraints during window resizing session. This function is triggered by a protocol called WindowResizeDelegate.
    func windowWillResize(_ sender: AnyObject?) {
        constraint = NSLayoutConstraint.constraints(withVisualFormat: "[firstview(\(splitviewLeft.frame.width))]", options: NSLayoutConstraint.FormatOptions.alignmentMask, metrics: nil, views: ["firstview": splitviewLeft])
        constraint2 = NSLayoutConstraint.constraints(withVisualFormat: "[secondview(\(splitviewMiddle.frame.width))]", options: NSLayoutConstraint.FormatOptions.alignmentMask, metrics: nil, views: ["secondview": splitviewMiddle])
        
        splitviewLeft.addConstraints(constraint)
        splitviewMiddle.addConstraints(constraint2)
    }
    
    // We remove the constraints later.
    func windowHasResized(_ sender: AnyObject?) {
        splitviewLeft.removeConstraints(constraint)
        splitviewMiddle.removeConstraints(constraint2)
        self.adjustBottomInset()
    }
    
    // Datasource method for table view
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView == EATableView {
            return 4
        } else {
            if EATableView.selectedRow == -1 {
                return 0
            } else {
                return visibleEAs.filter({currentFilterColor == "_" || $0.color == currentFilterColor}).count
            }
        }
    }
    
    // Datasource method for table view
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        if tableView == EATableView {
            return 48
        } else {
            // This is tricky. I spent around a week just to figure out how to calculate the exact height of each tableview cell according the amount of text entered by the user. This method is not available on the Internet!
            let textviewHeight = calculateHeightForFont(NSFont(name: "Helvetica Neue", size: 11.2)!, text: visibleEAs[row].description, width: EADetailTable.frame.width - 36, label: true)
            return 74 + textviewHeight
        }
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if tableView == EATableView {
            let cell = EATableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EA Category View"), owner: self) as! EACellView
            cell.eaLabel.stringValue = EACategories[row]
            return cell
        } else {
//            if removedRows.count != 0 {
//                let remaining = NSMutableIndexSet(indexesInRange: NSMakeRange(0, visibleEAs.count))
//                for i in removedRows {
//                    remaining.removeIndex(i)
//                }
//                if row >= remaining.count {return nil}
//                row = Array(remaining)[row]
//            }
            let cell = EADetailTable.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "EA Info"), owner: self) as! EAInfo
//            var ea = visibleEAs[row]
//            let ea = sortEAs(EAs[["All EAs", "EAs Pending", "EAs I Joined"][EATableView.selectedRow]]!.filter({currentFilterColor == "_" || $0.color == currentFilterColor}))[row]
            let ea = visibleEAs[row]
//            cell.layer?.backgroundColor = NSColor.whiteColor().CGColor
            cell.EAname.stringValue = ea.name
//            cell.EAdescription.stringValue =
            cell.EAdescription.stringValue = ea.description.decodedString
            //cell.EAdescription.refresh()
            cell.EATime.stringValue = ea.time
            if ea.approval != "Approved" {
                cell.enabled = false
                cell.EATime.stringValue = ea.approval
            } else {
                cell.enabled = true
            }
            
            let font = NSFont(name: "Helvetica Neue", size: 11.2)!
            cell.EAdescription.font = font

            let boxHeight = calculateHeightForFont(font, text: cell.EAdescription.stringValue, width: cell.EAdescription.frame.width, label: true)
            
            cell.EAdescription.frame = NSMakeRect(18, cell.frame.height - boxHeight - 62, cell.frame.width - 36, 100.0)
            (cell.EAdescription as! AutoResizingTextField).refresh()
            
            cell.color = ea.color
            if enableColors.checked {
                cell.background.alphaValue = 1
            } else {
                cell.background.alphaValue = 0
            }
            
            let contact = ea.type == "Teacher" ? "" : "\nContact Email(s): \(ea.email)"
            let supervisor = ea.type == "Teacher" ? "\nContact Email: \(ea.supervisor)" : "\nSupervisor: \(ea.supervisor)"
//            let contact = "\nContact Email(s): \(ea.id)@mybcis.cn"
//            let supervisor = "\nSupervisor: \(ea.supervisor)"
            
            cell.toolTip = "\(ea.name):\n\nName of Leader(s): \(ea.leader)" +
                contact +
                supervisor +
            "\nLocation: \(ea.location)" +
            "\nPeriod: \(ea.startDate) – \(ea.endDate)"
            
            
            if ea.dates == "" {
                cell.toolTip! += "\nThe date of the next session is unknown."
            } else {
                let formatter = DateFormatter()
                formatter.dateFormat = "MMM. d, y"
                formatter.locale = Locale(identifier: "en_US")
                let currentDate = formatter.date(from: formatter.string(from: Date()))!
                let EADate = updateDatesForEA(ea) // The next date (or the last date if the EA is over)
                if  ea.approval == "Approved" {
                    if formatter.date(from: ea.endDate)!.timeIntervalSince(currentDate) < 0 {
                        cell.toolTip! += "\nThis EA is over."
                    } else if formatter.date(from: EADate)!.timeIntervalSince(currentDate) >= 0 {
                        cell.toolTip! += "\nNext Session: \(EADate)"
                    } else {
                        cell.toolTip! += "\nThis EA is over."
                    }
                    
                }
            }
            
            cell.like.image = ea.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite") : #imageLiteral(resourceName: "Favorite_outline")
            cell.like.isEnabled = appstudentID != ""
            cell.numberOfLikes.integerValue = ea.favorites == "" ? 0 : ea.favorites.components(separatedBy: " | ").count
            
            return cell
        }
    }
    
    func updateDatesForEA(_ theEA: EA) -> String {
                
        if theEA.dates == "" {return "Unknown"}
        
        let formatter = DateFormatter()
        
        let exactTimeString = theEA.time.components(separatedBy: " | ").last!
        
        let exactTime = exactTimeString.components(separatedBy: " ").last!
        
        formatter.dateFormat = "MMM. d, y"
        formatter.locale = Locale(identifier: "en_US")
        let today = formatter.string(from: Date()) + " @ " + exactTime + " PM"
        
        let formatter2 = DateFormatter()
        formatter2.dateFormat = "MMM. d, y @ h:mm a"
        formatter2.locale = Locale(identifier: "en_US")
        
        for i in theEA.dates.components(separatedBy: " | ") {
            if formatter.date(from: i)!.timeIntervalSince(formatter2.date(from: today) ?? formatter2.date(from: formatter.string(from: Date()) + " @ 4:30 PM")!) >= 0 {
                return i
            }
        }
        
        
        return theEA.dates.components(separatedBy: " | ").last!
        
    }
    
    var nextEATableViewRow = 0
    
    @discardableResult
    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        
        if !initialization {
            initialization = true
            return true
        }
        
        posterLoadingLabel.isHidden = true
        
        if tableView == EATableView {
            visibleEAs = []
            noResults.isHidden = true
//            spinner.startAnimation(nil)
            nextEATableViewRow = row
            if row == 0 {bottomInfoLabel.stringValue = "Loading..."}
//            removedRows.removeAllIndexes()
            currentFilterColor = "_"
            colorCodes.reset()
            loadFromServer(row)
            if #available(OSX 10.12.2, *) {
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, .tenicLabel, NSTouchBarItem.Identifier.flexibleSpace]
            }
//            sortCriterion.isEnabled = row == 0
        } else if tableView == EADetailTable {
            if row + 1 > tableView.numberOfRows {
                print("error row: \(row)")
                return false
            }
            let targetCell = EADetailTable.view(atColumn: 0, row: row, makeIfNecessary: true) as! EAInfo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                targetCell.backgroundStyle = .dark
                tableView.becomeFirstResponder()
            }
            if targetCell.enabled {
                if #available(OSX 10.12.2, *) {
                    self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, .tenicLabel, NSTouchBarItem.Identifier.flexibleSpace]
                }
                EA_Name.stringValue = targetCell.EAname.stringValue
                signupBackground.isHidden = false
                signupLabel.stringValue = "Checking your status on this EA..."
                signupSpinner.startAnimation(nil)
                signupButton.isHidden = true
                EAList("update")
//                downloadSpinner.alphaValue = 1
                message.string = ""
                if FileManager().fileExists(atPath: NSTemporaryDirectory() + EA_Name.stringValue + ".rtfd") && downloadQueue[EA_Name.stringValue] == nil {
//                    The poster has already been downloaded
                    self.posterLoadingLabel.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.message.readRTFD(fromFile: NSTemporaryDirectory() + self.EA_Name.stringValue + ".rtfd")
                        self.hiddenMessage.readRTFD(fromFile: NSTemporaryDirectory() + self.EA_Name.stringValue + ".rtfd")
                        self.messageScrollView.isHidden = false
                        self.adjustImages(self.message)
                        self.adjustImages(self.hiddenMessage)
                        self.adjustBottomInset()
                        self.posterLoadingLabel.isHidden = true
                    }
                    signupSpinner.stopAnimation(nil)
                    percentage.stringValue = ""
                    downloadImage.stopAnimation()
                } else if downloadQueue[EA_Name.stringValue] != nil {
                    if downloadQueue[EA_Name.stringValue]?.total > 1 {
                        // The EA has a poster but has not been downloaded yet
                        let p = Double(downloadQueue[EA_Name.stringValue]!.downloaded) / Double(downloadQueue[EA_Name.stringValue]!.total) * 100
                        percentage.stringValue = "\(Int(p))%"
                        let vipImage = VIP[EA_Name.stringValue] ?? "Cloud Sync"
                        downloadImage.startAnimation(vipImage)
                    } else if downloadQueue[EA_Name.stringValue]?.total == 0 {
                        // The EA does not have a poster.
                        percentage.stringValue = ""
                        downloadImage.stopAnimation()
                        message.string = "No description available."
                        message.scrollToBeginningOfDocument(nil)
                        message.font = NSFont(name: "Helvetica", size: 12.5)
                        message.alignment = .left
                        message.textColor = NSColor.black
                    }
                } else {
                    let vipImage = VIP[EA_Name.stringValue] ?? "Cloud Sync"
                    downloadImage.startAnimation(vipImage)
                    updateDescription(EA_Name.stringValue)
                    percentage.stringValue = "0%"
                    message.enclosingScrollView?.isHidden = true
                }

            }
            
            
            return targetCell.enabled
        } else {
            print("row unknown \(row)")
        }
        
        
        return true
    }
    
    func adjustBottomInset() {
        let offset = hiddenMessage.enclosingScrollView!.frame.height - hiddenMessage.frame.height
        if offset >= 0 {
            messageScrollView.contentInsets.bottom = 0
        } else if offset < -48 {
            messageScrollView.contentInsets.bottom = 48
        } else {
            messageScrollView.contentInsets.bottom = -offset
        }
    }
    
    func adjustImages(_ textView: NSTextView) {
        if #available(OSX 10.11, *) {
            if !textView.enclosingScrollView!.isHidden && textView.attributedString().containsAttachments {
                var content = textView.getParts()
                let images = textView.getAlignImages()
                let attributedImages = textView.getAttributedAlignImages()
                
                var indexOfAlignImages = [Int]()
                
                for i in 0..<content.count {
                    if content[i].containsAttachments {
                         indexOfAlignImages.append(i)
                    }
                }
                

                let newImages = images.map {image -> NSImage in
                    let scaleFactor = (textView.frame.width - 10) / image.size.width
                    image.size.width *= scaleFactor
                    image.size.height *= scaleFactor
                    if image.size.width >= image.resolution.width {
                        image.size = image.resolution
                    }
                    return image
                }
                
                
                let newAttrStr = NSMutableAttributedString()
                
                var newImageCount = 0
                
                for i in 0..<content.count {
                    if !indexOfAlignImages.contains(i) {
                        newAttrStr.append(content[i])
                    } else {
                        let tmp = NSMutableAttributedString(attributedString: attributedImages[newImageCount])
                        var oldattr = attributedImages[newImageCount].attributes(at: 0, effectiveRange: nil)
                        let attachment = oldattr[NSAttributedStringKey.attachment] as! NSTextAttachment
                        attachment.attachmentCell = NSTextAttachmentCell(imageCell: newImages[newImageCount])
                        oldattr[NSAttributedStringKey.attachment] = attachment
                        tmp.addAttributes(oldattr, range: NSMakeRange(0, tmp.length))
                        newAttrStr.append(tmp)
                        newImageCount += 1
                    }
                }
                textView.textStorage?.setAttributedString(newAttrStr)
            }
        }
    }
    
    func tableViewColumnDidResize(_ notification: Notification) {
        adjustImages(message)
        adjustImages(hiddenMessage)
        adjustBottomInset()
    }
    
    
    @IBAction func refreshEATables(_ sender: NSButton) {
        empty()
        tableView(EATableView, shouldSelectRow: EATableView.selectedRow)
        colorCodes.reset()
    }
    
    func updateDescription(_ EA_Name: String) {
        let acceptableChars = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789_-")
        
        let name = EA_Name.addingPercentEncoding(withAllowedCharacters: acceptableChars)
        if EA_Name == self.EA_Name.stringValue {
            let vipImage = VIP[EA_Name] ?? "Cloud Sync"
            downloadImage.startAnimation(vipImage)
            message.string = ""
            percentage.stringValue = "0%"
        }
        Terminal().deleteFileWithPath(NSTemporaryDirectory() + EA_Name + ".rtfd")
        let request = URLRequest(url: URL(string: serverAddress + "EA/\(name!).zip")!)
        let download = NSURLDownload.init(request: request, delegate: self)
        download.setDestination(NSTemporaryDirectory() + EA_Name + ".zip", allowOverwrite: true)
        download.deletesFileUponFailure = true
        downloadQueue[EA_Name] = (download, 1, 0)
    }
    
    func downloadDidFinish(_ download: NSURLDownload) {
        percentage.stringValue = ""
        for i in Array(downloadQueue.keys) {
            if downloadQueue[i]!.download == download {
                downloadQueue[i] = nil
                let command = Terminal(launchPath: "/usr/bin/unzip", arguments: ["-o", i + ".zip"])
                command.currentPath = NSTemporaryDirectory()
                command.execUntilExit()
                command.deleteFileWithPath(NSTemporaryDirectory() + i + ".zip")
                command.launchPath = "/bin/mv"
                command.arguments = ["Description.rtfd", i + ".rtfd"]
                command.execUntilExit()
                if EA_Name.stringValue == i {
                    self.posterLoadingLabel.isHidden = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.downloadImage.stopAnimation()
                        self.message.readRTFD(fromFile: NSTemporaryDirectory() + self.EA_Name.stringValue + ".rtfd")
                        self.hiddenMessage.readRTFD(fromFile: NSTemporaryDirectory() + self.EA_Name.stringValue + ".rtfd")
                        self.message.enclosingScrollView?.isHidden = false
                        self.adjustImages(self.message)
                        self.adjustImages(self.hiddenMessage)
                        self.adjustBottomInset()
                        self.posterLoadingLabel.isHidden = true
                        self.message.scrollToBeginningOfDocument(nil)
                    }
                }
                break
            }
        }
    }
    
    func download(_ download: NSURLDownload, didFailWithError error: Error) {
        
        for i in Array(downloadQueue.keys) {
            if downloadQueue[i]!.download == download {
                downloadQueue[i] = (downloadQueue[i]!.download, 0, 0)
            }
        }
        
        if download == downloadQueue[EA_Name.stringValue]?.download {
            percentage.stringValue = ""
            downloadImage.stopAnimation()
            if error._code == -1100 {
                message.string = "No description available."
                message.font = NSFont(name: "Helvetica", size: 12.5)
                message.alignment = .left
                message.textColor = NSColor.black
                message.scrollToBeginningOfDocument(nil)
            } else {
                print(error)
            }
        }
    }
    
    
    //////////
    
    var loadQueue = 0
    
    //Fetching EAs from the server
    func loadFromServer(_ row: Int) {
        
        loadQueue += 1
        
//        EAs = ["All EAs": [EA](), "EAs Pending": [EA](), "EAs I Joined": [EA](), "Favorites": [EA]()]
//        shouldUpdateFavorites -= 1
//        (EATableView.view(atColumn: 0, row: 3, makeIfNecessary: false) as? EACellView)?.digit = 0
        
        if loadQueue == 1 {
            loadImage.startAnimation("Random")
        }
        
        message.enclosingScrollView?.isHidden = true
        reloadButton.isEnabled = false
        
        Thread.sleep(forTimeInterval: 0)
        colorCodes.enabled = false
        self.bottomInfoLabel.stringValue = "Loading..."
        let url = URL(string: serverAddress + "tenicCore/service.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let postString = "id=\(d.string(forKey: "ID")!)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            data, response, error in
            if error != nil || String(data: data!, encoding: String.Encoding.utf8)!.contains("<script>") {
                print("error=\(error!)")
//                if self.visibleEAs.count != 0 {return}
                DispatchQueue.main.async {
                    if self.visibleEAs.count > 0 {return}
                    let alert = NSAlert()
                    if !hasRunAlert {
                        firstAlertLayout(alert)
                    }
                    self.EAs = ["All EAs": [EA](), "EAs Pending": [EA](), "EAs I Joined": [EA](), "Favorites": [EA]()]
                    let favCell = self.EATableView.view(atColumn: 0, row: 3, makeIfNecessary: false) as? EACellView
                    favCell?.digit = 0
                    self.reloadButton.isEnabled = true
                    alert.messageText = "Let me get online!"
                    alert.informativeText = "Internet connection to me is like oxygen to you."
                    customizeAlert(alert, height: 0, barPosition: 0)
                    alert.addButton(withTitle: "OK")
                    alert.window.title = "Your Mac is Offline"
                    self.loadImage.stopAnimation()
                    self.bottomInfoLabel.stringValue = "Unable to Connect"
                    self.noResults.isHidden = false
                    self.sortCriterion.isEnabled = false
                    alert.runModal()
                    self.view.window?.makeKeyAndOrderFront(nil)
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSArray
                
                var EAs = [[String: String]]()
                
                for i in json {
                    EAs.append(i as! [String:String])
                }
                self.responsive = false
                var allEAs = [EA]()
                self.EAs["EAs I Joined"]?.removeAll()
                self.EAs["EAs Pending"]?.removeAll()
                self.EAs["Favorites"]?.removeAll()
                for i in EAs {
                    var myEA = EA(EA_Name: i["Name"]!, description: i["Description"]!, date: i["Date"]!, leader: i["Leader"]!, type: i["Type"]!, id: i["ID"]!, supervisor: i["Supervisor"]!, location: i["Location"]!, approval: i["Status"]!, age: i["Age"]!, max: i["Max"]!, dates: i["Dates"]!, startDate: i["Start Date"]!, endDate: i["End Date"]!, prompt: i["Prompt"]!.decodedString, frequency: Int(i["Frequency"]!) ?? 4, favorites: i["Favorites"]!)
                    myEA.availability = i["Availability"]!
                    myEA.participants = Int(i["Participants"]!) ?? 0
                    myEA.message = i["Message"]!
                    if i["Color"]!.contains("|") {
                        myEA.color = i["Color"]!.components(separatedBy: "|")[0]
                        self.VIP[myEA.name] = i["Color"]!.components(separatedBy: "|")[1]
                    } else {
                        myEA.color = i["Color"]!
                        self.VIP[myEA.name] = "Cloud Sync"
                    }
                    if myEA.approval != "Incomplete" && myEA.approval != "Hidden" {
                        allEAs.append(myEA)
                    }
                    if i["Availability"]! == "Approved" && appstudentID != "" {
                        self.EAs["EAs I Joined"]?.append(myEA)
                    } else if i["Availability"]! == "Pending" && appstudentID != "" {
                        self.EAs["EAs Pending"]?.append(myEA)
                    }
                    if i["Favorites"]!.contains(appstudentID) && appstudentID != "" {
                        self.EAs["Favorites"]?.append(myEA)
                    }
                }
                
                if appstudentID != "" {
                
                    let path: NSString = "~/Library/Application Support/Find my EA/.identity.tenic"
                    var identity = NSKeyedUnarchiver.unarchiveObject(withFile: path.expandingTildeInPath) as? [String:String] ?? [String:String]()
                    var subscription = self.EAs["EAs I Joined"]!.map({$0.name})
                    let leadingEAs = allEAs.filter({$0.id.contains(appstudentID)}).map({$0.name})
                    subscription += leadingEAs
                    identity["EAs"] = subscription.joined(separator: ", ")
                    NSKeyedArchiver.archiveRootObject(identity, toFile: path.expandingTildeInPath)
                    
                }
                
                
                // Delay
                if self.loadQueue == 1 {
                    Thread.sleep(forTimeInterval: loading_delay)
                }
                self.loadQueue -= 1
                
                if self.loadQueue != 0 {return}
                
                DispatchQueue.main.async {
                    self.visibleEAs = self.sortEAs(self.EAs[self.EACategories[self.EATableView.selectedRow]]!)
                }
                
                self.responsive = true
                
                DispatchQueue.main.async {
                    self.EAs["All EAs"] = self.sortEAs(allEAs)
                    let favCell = self.EATableView.view(atColumn: 0, row: 3, makeIfNecessary: false) as? EACellView
                    favCell?.digit = self.EAs["Favorites"]!.count

                    if row != self.EATableView.selectedRow {
                        return
                    }
                    self.loadImage.stopAnimation()
                    switch row {
                    case 0:
//                        self.responsive = false
//                        self.visibleEAs = self.EAs["All EAs"]!
//                        self.responsive = true
                        let noun = allEAs.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(allEAs.count) " + noun + " in total."
                    case 1:
//                        self.responsive = false
//                        self.visibleEAs = self.EAs["EAs Pending"]!
//                        self.responsive = true
                        let noun = self.EAs["EAs Pending"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(self.EAs["EAs Pending"]!.count) " + noun + " pending."
                    case 2:
//                        self.responsive = false
//                        self.visibleEAs = self.EAs["EAs I Joined"]!
//                        self.responsive = true
                        let noun = self.EAs["EAs I Joined"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(self.EAs["EAs I Joined"]!.count) " + noun + " joined."
                    case 3:
                        let noun = self.visibleEAs.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "You have \(self.visibleEAs.count) favorite " + noun + "."
                    default:
                        break
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        self.EADetailTable.reloadData()
                        self.reloadButton.isEnabled = true
                    }
                    self.controlTextDidChange(Notification(name: Notification.Name(rawValue: ""), object: self.searchField))
//                self.spinner.stopAnimation(nil)
                }
            } catch let err {
                print("connection error: \(err)")
                self.reloadButton.isEnabled = true
            }
            
        }) 
        task.resume()

    }
    
    @IBAction func signUp(_ sender: NSButton) {
        
        // Get the EA object that the user is signing up for
        
        signupEA_Name = EA_Name.stringValue
        let theEA = visibleEAs.filter({(myEA) -> Bool in
            return myEA.name == EA_Name.stringValue
        })[0]
        
        // Instantiate and alert
        
        let alert = NSAlert()
        if !hasRunAlert {
            firstAlertLayout(alert)
        }
        
        if appstudentID == "" {
            alert.messageText = "You are not currently logged in."
            alert.informativeText = "Please make sure you are logged in before signing up for an EA."
            customizeAlert(alert, height: 0, barPosition: 0)
            alert.addButton(withTitle: "OK").keyEquivalent = "\r"
            alert.runModal()
            return
        }
        
        alert.messageText = "Are you sure?"
        if signupButton.title == "Join" {
            var email = theEA.email
            if theEA.type == "Teacher" {
                email = theEA.supervisor
            }
            alert.informativeText = "If you continue, your information will be sent to the EA leader(s) of \(EA_Name.stringValue) (\(theEA.leader)).\n\nAlternatively, you can email the leader(s):\n" + email
            alert.window.title = "\(EA_Name.stringValue) Registration"

        } else if signupButton.title == "Cancel" {
            alert.informativeText = "If you continue, your request to join \(EA_Name.stringValue) will be cancelled."
            alert.window.title = "Cancel Request for \(EA_Name.stringValue)"
            customizeAlert(alert, height: 0, barPosition: 0)
        } else {
            alert.informativeText = "If you continue, you will leave this EA."
            alert.window.title = "Leave \(EA_Name.stringValue)"
            customizeAlert(alert, height: 0, barPosition: 0)
        }

        alert.addButton(withTitle: "Continue").keyEquivalent = "\r"
        alert.addButton(withTitle: "Cancel")

        let textfield = NSTextField(frame: NSRect(x: 0, y: 0, width: 292, height: 22))
        if sender.title == "Join" {
            textfield.placeholderString = theEA.prompt == "" ? "Leave a message for the EA Leader? (optional)" : theEA.prompt
            
            let proposedHeight = calculateHeightForFont(NSFont.systemFont(ofSize: 12), text: textfield.placeholderString!, width: 292, label: false)
            print(proposedHeight)
            
            textfield.textColor = NSColor.black
            textfield.backgroundColor = NSColor(red: 0.97, green: 0.98, blue: 1, alpha: 1)
            textfield.alphaValue = 0.9
            textfield.cell?.wraps = true
            alert.accessoryView = textfield
            print(alert.window.contentView!.frame)
            textfield.frame = NSRect(origin: textfield.frame.origin, size: CGSize(width: 288, height: proposedHeight))
            alert.accessoryView?.appearance = NSAppearance(named: NSAppearance.Name.aqua)
            customizeAlert(alert, height: 0, barPosition: proposedHeight + 20)
        }
        

        alert.icon = NSApplication.shared.applicationIconImage
        
        if alert.runModal() == NSApplication.ModalResponse.alertSecondButtonReturn {
            return
        }
        if textfield.stringValue == "" {textfield.stringValue = "N/A"}
        
        // Upload information to MySQL database through NSURLSession
        
        let url = URL(string: serverAddress + "tenicCore/signup.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"

        var hasRun = false
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "MMM. d, y"
        let postString = "name=\(appfullname)&id=\(appstudentID)&ea=\(EA_Name.stringValue)&action=\(signupButton.title)&message=\(textfield.stringValue.encodedString)&date=\(formatter.string(from: Date()))"
        signupLabel.stringValue = "Sending information..."
        signupButton.isHidden = true
        
        if #available(OSX 10.12.2, *) {
            let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): Sending information...")
            self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, touchbarLabel, NSTouchBarItem.Identifier.flexibleSpace]
        }
        
        signupSpinner.startAnimation(nil)
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        // Specify the session task
        let uploadtask = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if hasRun {return}
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary as! [String:String]
                if json["status"] == "success" {
                    
                    // Run the following block of code on main thread
                    DispatchQueue.main.async {
                        let finishAlert = NSAlert()
                        // If user is joining the EA
                        
                        if self.signupButton.title == "Join" {
                            self.updateEAStatus("Pending")
                            finishAlert.messageText = "Signup request sent!"
                            finishAlert.informativeText = "Your information will be processed by the EA Leader, good luck!"
                            customizeAlert(finishAlert, height: 0, barPosition: 0)
                            finishAlert.window.title = "Request Sent"
                            self.EAs["EAs Pending"]?.append(theEA)
                            if #available(OSX 10.12.2, *) {
                                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(self.EA_Name.stringValue): ")
                                let touchbarButton = NSTouchBarItem.Identifier(rawValue: "Button: Cancel")
                                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, touchbarLabel, touchbarButton, NSTouchBarItem.Identifier.flexibleSpace]
                            }
                            
                        } else if self.signupButton.title == "Cancel" {
                            
                            //If user is cancelling the request
                            
                            self.updateEAStatus("New")
                            finishAlert.messageText = "Signup request cancelled."
                            finishAlert.informativeText = "If you have cancelled in time, the EA leader would not have seen your signup request."
                            customizeAlert(finishAlert, height: 0, barPosition: 0)
                            finishAlert.window.title = "Signup Request Cancelled"
//                            self.empty()
                            
                            DispatchQueue.main.async {self.empty()}
                            
                        } else if self.signupButton.title == "Leave" {
                            self.updateEAStatus("New")
                            finishAlert.messageText = "You have left \(self.EA_Name.stringValue)"
                            finishAlert.informativeText = "Deep inside your mind, I know you wish you could drop school classes like this :)"
                            customizeAlert(finishAlert, height: 0, barPosition: 0)
                            if self.EATableView.selectedRow != 0 {
                                self.empty()
                            }
                            
                        }
                        
                        // Activate finishing alert
                        
                        finishAlert.icon = NSApplication.shared.applicationIconImage
                        finishAlert.addButton(withTitle: "Dismiss").keyEquivalent = "\r"
                        finishAlert.runModal()
                    }
                } else {
                    if json["message"] == "EA is full." {
                        DispatchQueue.main.async {
                            self.updateEAStatus("Full")
                            let alert = NSAlert()
                            customizeAlert(alert, height: 0, barPosition: 0)
                            alert.messageText = "EA is full!"
                            alert.informativeText = "This EA has reached its maximum capacity. Please contact the leader for further details."
                            alert.window.title = "Too Late to Join"
                            alert.addButton(withTitle: "Fine").keyEquivalent = "\r"
                            alert.runModal()
                        }
                    }
                }
                
            } catch {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
//                print("error=\(error)")
            }
            hasRun = true
            return
        }
        // Begin
        uploadtask.resume()
        
        // Send a notification to the leader
        let message = appfullname + " from " + appadvisory
        if signupButton.title == "Join" {
            broadcastMessage("Found my EA", message: message + " would like to join your " + signupEA_Name + ".", filter: "I:\(theEA.id)", msgdate: nil)
        } else if signupButton.title == "Cancel" {
            broadcastMessage("Found my EA", message: message + " would like to join your " + signupEA_Name + ".", filter: "I:\(theEA.id)", msgdate: "Delete")
        } else if signupButton.title == "Leave" {
            broadcastMessage("Found my EA", message: message + " has left your " + signupEA_Name + ".", filter: "I:\(theEA.id)", msgdate: nil)
        }
    }
    
    func tableView(_ tableView: NSTableView, shouldTypeSelectFor event: NSEvent, withCurrentSearch searchString: String?) -> Bool {
        return false
    }
    
    func EAList(_ action: String) {
        let url = URL(string: serverAddress + "tenicCore/EAList.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let id = d.string(forKey: "ID")!
        let postString = "id=\(id)&action=\(action)"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                print(error!)
                self.updateEAStatus("Connection Error")
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary
                self.userEAStatus = json as! [String:String]
                DispatchQueue.main.async {
                    
                    if action == "update" {
//                        print(self.EA_Name.stringValue + "->", separator: "", terminator: "")
//                        print(self.userEAStatus)
                        let list = Array(self.userEAStatus.keys)
                        if list.contains(self.EA_Name.stringValue) {
                            let result = self.userEAStatus[self.EA_Name.stringValue]!.components(separatedBy: "**")
                            let formatter = DateFormatter()
                            formatter.locale = Locale(identifier: "en_US")
                            formatter.dateFormat = "MMM. d, y"
                            let startDates = result[1].components(separatedBy: "|")
                            let endDates = result[2].components(separatedBy: "|")
                            
                            if startDates.count == endDates.count && endDates.first! != "" {
                                self.updateEAStatus("Rejoin")
                            } else if appstudentID == "SSEA" {
                                self.updateEAStatus("SSEA")
                            } else {
                                self.updateEAStatus(result[0])
                            }
                        } else {
                            self.updateEAStatus("")
                        }
                    } else if action == "pending" {
                        self.updateEAs("Pending")
                    } else if action == "joined" {
                        self.updateEAs("Joined")
                    }
                }
            } catch {
                print("error=\(error)")
            }
            return
        }
        
        task.resume()

    }
    
    func updateEAs(_ type: String) {
        let EA_Namelist = Array(userEAStatus.keys)
        var joined_EAs = [String]()
        var pending_EAs = [String]()
        for i in EA_Namelist {
            if userEAStatus[i]! == "Pending" {
                pending_EAs.append(i)
            } else if userEAStatus[i]! == "Approved" {
                joined_EAs.append(i)
            }
        }
        
        EAs["EAs Pending"] = EAs["All EAs"]?.filter {(myEA) -> Bool in
            return pending_EAs.contains(myEA.name)
        }
        
        EAs["EAs I Joined"] = EAs["All EAs"]?.filter {(myEA) -> Bool in
            return joined_EAs.contains(myEA.name)
        }
        
        EAs["Favorites"] = EAs["All EAs"]?.filter {(myEA) -> Bool in
            return myEA.favorites.contains(appstudentID) && appstudentID != ""
        }
        
        if type == "Pending" && EATableView.selectedRow == 1 {
            visibleEAs = EAs["EAs Pending"]!
        } else if type == "Joined" && EATableView.selectedRow == 2 {
            visibleEAs = EAs["EAs I Joined"]!
        } else if type == "Favorites" && EATableView.selectedRow == 3 {
            visibleEAs = EAs["Favorites"]!
        }
//        spinner.stopAnimation(nil)
//        loadImage.hidden = true
        loadImage.stopAnimation()
    }
    
    //Update the EA banner depending on "status"
    
    func updateEAStatus(_ status: String) {
        if EA_Name.stringValue == "" {return}
        
        signupSpinner.stopAnimation(nil)
        signupButton.isHidden = false
        signupLabel.toolTip = nil
        
        var theEA = EAs["All EAs"]!.filter({item -> Bool in
            return item.name == EA_Name.stringValue
        })[0]
        
        if status == "SSEA" {
            signupLabel.stringValue = "This is a test account and cannot be used to signup."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): System account cannot signup.")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        
        
        if isTeacher {
            signupLabel.stringValue = "Sorry. Teachers cannot sign up for EAs."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        
        if appstudentID == "" {
            signupLabel.stringValue = "You are not currently logged in."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        
        if theEA.age == "" {theEA.age = " | "}
        
        let entryYear = String(Array(appstudentID.characters)[0...3])
        var entryGrade = String(Array(appstudentID.characters)[7...8])
        if entryGrade == "16" {
            entryGrade = "0"
        } else if entryGrade == "15" {
            entryGrade = "-1"
        } else if entryGrade == "14" {
            entryGrade = "-2"
        } else if entryGrade == "13" {
            entryGrade = "-3"
        }
        
        let date = Date().addingTimeInterval(-86400 * 30 * 7) // August
        let formatter = DateFormatter()
        formatter.dateFormat = "y"
        formatter.locale = Locale(identifier: "en_US")
        let currentGrade = Int(formatter.string(from: date))! - (Int(entryYear) ?? 0) + (Int(entryGrade) ?? 1)
        print(currentGrade)
        var min = 0
        if theEA.age.components(separatedBy: " | ")[0] != "" {
            min = Int(theEA.age.components(separatedBy: " | ")[0])!
        }
        var max = 12
        if theEA.age.components(separatedBy: " | ")[1] != "" {
            max = Int(theEA.age.components(separatedBy: " | ")[1])!
        }
        
        if isTeacher && appfullname.lowercased() == theEA.supervisor.lowercased() {
            signupLabel.stringValue = "You are the supervisor of this EA."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
    
        if min > currentGrade {
            signupLabel.stringValue = "The EA requires a minimum grade of \(min)"
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        if max < currentGrade {
            signupLabel.stringValue = "The EA requires a maximum grade of \(max)."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        
        formatter.dateFormat = "MMM. d, y"
        let today = formatter.date(from: formatter.string(from: Date()))!
        
        let eaEndDate = formatter.date(from: theEA.dates.components(separatedBy: " | ").last!) ?? formatter.date(from: theEA.endDate)!
        
        if today.timeIntervalSince(eaEndDate) > 0 {
            signupLabel.stringValue = "The EA has already finished running since \(formatter.string(from: eaEndDate))."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
            return
        }
        
//        
//        if Date().timeIntervalSince(formatter.date(from: theEA.startDate)!) < 0 {
//            signupLabel.stringValue = "This EA hasn't open registration yet!"
//            signupButton.isHidden = true
//            
//            if #available(OSX 10.12.2, *) {
//                let touchbarLabel = NSTouchBarItemIdentifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
//                let backButton = NSTouchBarItemIdentifier(rawValue: "Button: Back")
//                self.touchBar?.defaultItemIdentifiers = [.flexibleSpace, touchbarLabel, backButton, .flexibleSpace]
//            }
//            
//            return
//        }
        
        switch status {
            
        case "New":
            
            signupLabel.stringValue = "Interested in joining? Press the join button to send a signup request:"
            signupButton.title = "Join"
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): Press “Join” to join this EA.")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                let joinButton = NSTouchBarItem.Identifier(rawValue: "Button: Join")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, joinButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }

            
            if EATableView.selectedRow == 1 && visibleEAs.count != 0 {
                for i in 0..<visibleEAs.count {
                    if visibleEAs[i].name == signupEA_Name {
                        
                        if i == EADetailTable.selectedRow {
                            EADetailTable.deselectAll(nil)
                        }
                        
                        //Physically delete the row if it is no longer part of "pending" EAs
//                        EADetailTable.removeRowsAtIndexes(NSIndexSet(index: i), withAnimation: .EffectFade)
                        visibleEAs.remove(at: i)
                        
                        //Update the main EA dictionary
                        EAs["EAs Pending"] = visibleEAs
                        
                        
                        for i in 0..<EAs["All EAs"]!.count {
                            if EAs["All EAs"]![i].name == signupEA_Name {
                                EAs["All EAs"]![i].availability = ""
                            }
                        }
                        
                        return
                    }
                }
                
            } else if EATableView.selectedRow == 2 && visibleEAs.count != 0 {
                for i in 0..<visibleEAs.count {
                    if visibleEAs[i].name == signupEA_Name {
                        
                        if i == EADetailTable.selectedRow {
                            EA_Name.stringValue = ""
                            signupBackground.isHidden = true
                        }
                        
                        //Physically delete the row if it is no longer part of "pending" EAs
                        EADetailTable.removeRows(at: IndexSet(integer: i), withAnimation: NSTableView.AnimationOptions.effectFade)
                        visibleEAs.remove(at: i)
                        
                        //Update the main EA dictionary
                        EAs["EAs I Joined"] = visibleEAs
                        
                        for i in 0..<EAs["All EAs"]!.count {
                            if EAs["All EAs"]![i].name == signupEA_Name {
                                EAs["All EAs"]![i].availability = ""
                            }
                        }
                        
                        return
                    }
                }
            }
            
        case "Approved":
            signupLabel.stringValue = "You are currently enrolled in this activity."
            signupButton.title = "Leave"
            let theEA = EAs["All EAs"]!.filter({(item) -> Bool in
                return EA_Name.stringValue == item.name
            })[0]
            if theEA.message != "N/A" {
                signupLabel.toolTip = "The EA leader has left the following message:\n\n" + theEA.message
            }
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Leave")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
        case "Leader":
            signupLabel.stringValue = "You are the leader of this EA."
            signupButton.isHidden = true
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): \(signupLabel.stringValue)")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
        case "Pending":
            
            signupLabel.stringValue = "Waiting for confirmation from the EA Leader..."
            signupButton.title = "Cancel"
            let theEA = EAs["All EAs"]!.filter({(item) -> Bool in
                return EA_Name.stringValue == item.name
            })[0]
            if theEA.message != "N/A" {
                signupLabel.toolTip = "The EA leader has left the following message:\n\n" + theEA.message
            }
            
            if #available(OSX 10.12.2, *) {
                let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): ")
                let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Cancel")
                let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
                self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
                (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
            }
            
        case "Unapproved":
            signupLabel.stringValue = "The leader has denied your enrollment for this EA."
            signupButton.isHidden = true
        case "Full":
            signupLabel.stringValue = "This EA is full."
            signupButton.isHidden = true
        case "Full+Leader":
            signupLabel.stringValue = "You are the leader of this EA, and it is full."
            signupButton.isHidden = true
        case "Rejoin":
            signupLabel.stringValue = "You have once quit from this EA. Click 'Join' to rejoin."
            signupButton.isHidden = false
        case "Connection Error":
            signupLabel.stringValue = "Your computer is not connected to the internet."
            signupButton.isHidden = true
        case "SSEA":
            signupLabel.stringValue = "This is a test account and cannot be used to signup."
            signupButton.isHidden = true
        default:
            signupLabel.stringValue = "Unknown Status"
            signupButton.isHidden = true
        }
        
        if #available(OSX 10.12.2, *), ["Unapproved", "Full", "Full+Leader", "Rejoin", "Connection Error", "SSEA"].contains(status) {
            let touchbarLabel = NSTouchBarItem.Identifier(rawValue: "Label: \(EA_Name.stringValue): ")
            let backButton = NSTouchBarItem.Identifier(rawValue: "Button: Back")
            let likeButton = NSTouchBarItem.Identifier(rawValue: "Button: Like")
            self.touchBar?.defaultItemIdentifiers = [NSTouchBarItem.Identifier.flexibleSpace, likeButton, touchbarLabel, backButton, NSTouchBarItem.Identifier.flexibleSpace]
            (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = theEA.favorites.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
        }
        
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        if EADetailTable.selectedRow == -1 {
            empty()
            if #available(OSX 10.12.2, *) {
                self.touchBar = self.makeTouchBar()
            }
            
        } else {
            colorCodes.isHidden = true
        }
    }
    
    @objc func empty() {
        signupBackground.isHidden = true
        downloadImage.stopAnimation()
        message.enclosingScrollView?.isHidden = true
        EA_Name.stringValue = ""
        percentage.stringValue = ""
        colorCodes.isHidden = false
        EADetailTable.deselectAll(nil)
        if #available(OSX 10.12.2, *) {
            self.touchBar = self.makeTouchBar()
        }
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        if loadImage.isAnimating {return}
        let searchField = obj.object as! NSSearchField
        visibleEAs = filterEAs(sortEAs(EAs[EACategories[EATableView.selectedRow]]!.filter({$0.color == currentFilterColor || currentFilterColor == "_"})), keyword: searchField.stringValue, filter: currentFilterColor)
        empty()
    }
    
    func menuWillOpen(_ menu: NSMenu) {
        let cursor = NSEvent.mouseLocation
        let cursorInWindow = NSPoint(x: cursor.x - (view.window?.frame.origin.x)!, y: cursor.y - (view.window?.frame.origin.y)!)
        rightclickRowIndex = EADetailTable.row(at: EADetailTable.convert(cursorInWindow, from: view))
        EADetailTable.menu?.removeAllItems()
        EADetailTable.menu?.addItem(withTitle: "Reload", action: #selector(ViewController.reloadRow), keyEquivalent: "")
    }
    
    @objc func reloadRow() {
        let cell = EADetailTable.view(atColumn: 0, row: rightclickRowIndex, makeIfNecessary: false) as! EAInfo
        Terminal().deleteFileWithPath(NSTemporaryDirectory() + cell.EAname.stringValue + ".zip")
        updateDescription(cell.EAname.stringValue)
    }
    
    func download(_ download: NSURLDownload, didReceive response: URLResponse) {
        for i in Array(downloadQueue.keys) {
            if downloadQueue[i]!.download == download {
                downloadQueue[i] = (downloadQueue[i]!.download, Int(response.expectedContentLength), 0)
            }
        }
        if download == downloadQueue[EA_Name.stringValue]?.download {
            percentage.stringValue = "0%"
            let vipImage = VIP[EA_Name.stringValue] ?? "Cloud Sync"
            downloadImage.startAnimation(vipImage)
        }
    }
    
    func download(_ download: NSURLDownload, didReceiveDataOfLength length: Int) {
        for i in Array(downloadQueue.keys) {
            if downloadQueue[i]!.download == download {
                let oldLength = downloadQueue[i]!.2
                downloadQueue[i] = (downloadQueue[i]!.download, downloadQueue[i]!.total, oldLength + length)
            }
        }
        if downloadQueue[EA_Name.stringValue]?.download == download {
            let fullLength = downloadQueue[EA_Name.stringValue]!.total
            let downloadedLength = downloadQueue[EA_Name.stringValue]!.downloaded
            let p = Double(downloadedLength) / Double(fullLength) * 100
            percentage.stringValue = "\(Int(p))%"
        }
    }
    
    @IBAction func enableColors(_ sender: ITSwitch) {
//        let index = NSIndexSet(indexesInRange: NSMakeRange(0, visibleEAs.count - removedRows.count))
//        EADetailTable.reloadDataForRowIndexes(index, columnIndexes: NSIndexSet(index: 0))
        for i in 0..<EADetailTable.numberOfRows {
            let cell = EADetailTable.view(atColumn: 0, row: i, makeIfNecessary: false) as? EAInfo
            if enableColors.checked {
                cell?.background.alphaValue = 1
            } else {
                cell?.background.alphaValue = 0
            }
        }
        d.set(enableColors.checked, forKey: "Color Code")
    }
    
    func filterEA(_ filter: String) { // When the user selects a category color
        if filter != "_" {

            let old = visibleEAs
            
            responsive = false
            print(sortEAs(EAs[EACategories[EATableView.selectedRow]]!).filter({$0.color == filter}))
            visibleEAs = filterEAs(sortEAs(EAs[EACategories[EATableView.selectedRow]]!).filter({$0.color == filter}), keyword: searchField.stringValue, filter: filter)
            responsive = true
            
            if #available(OSX 10.12.2, *) {
                self.touchBar = self.makeTouchBar()
            }
            
            let newNames = visibleEAs.map({$0.name})
            
            if currentFilterColor == "_" {
                // This means the user has just applied a filter from an unfiltered state
                
                let rowsToRemove = NSMutableIndexSet()
                for i in 0..<EADetailTable.numberOfRows {
                    if !newNames.contains(old[i].name) {
                        rowsToRemove.add(i)
                    }
                }
                EADetailTable.removeRows(at: rowsToRemove as IndexSet, withAnimation: NSTableView.AnimationOptions.effectFade)
            } else { // The user switches to a new color filter
                // First, all previous rows need to be deleted (no EA shares two or more categories)
                
                EADetailTable.removeRows(at: IndexSet(integersIn: 0..<old.count), withAnimation: NSTableView.AnimationOptions.effectFade)
                // Then, add in the number of rows required to display the new contents
                EADetailTable.insertRows(at: IndexSet(integersIn: 0..<visibleEAs.count), withAnimation: NSTableView.AnimationOptions.effectFade)
            }
            
            currentFilterColor = filter

        } else {
            currentFilterColor = "_"
            let old = visibleEAs
            let oldNames = old.map {$0.name}
//            removedRows.removeAllIndexes()
            responsive = false
            visibleEAs = filterEAs(sortEAs(EAs[EACategories[EATableView.selectedRow]]!), keyword: searchField.stringValue, filter: "_")
            responsive = true
            if #available(OSX 10.12.2, *) {
                self.touchBar = self.makeTouchBar()
            }
            for i in 0..<visibleEAs.count {
                if !oldNames.contains(visibleEAs[i].name) {
                    EADetailTable.insertRows(at: IndexSet(integer: i), withAnimation: NSTableView.AnimationOptions.effectFade)
                }
            }
//            EADetailTable.insertRows(at: tmp as IndexSet, withAnimation: .effectFade)
        }
    }
    
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
//        DispatchQueue.main.async {self.adjustImages()}
        return subview != splitView.subviews[2]
        
    }
    
    @IBAction func changeSortingCriterion(_ sender: NSPopUpButton) {
        visibleEAs = sortEAs(visibleEAs)
        if currentFilterColor == "_" {
            visibleEAs = filterEAs(visibleEAs, keyword: searchField.stringValue, filter: "_")
        } else {
            visibleEAs = visibleEAs.filter({currentFilterColor == "_" || $0.color == currentFilterColor})
        }
        
        d.set(["Popularity", "Alphabetical Order", "# of Participants"].index(of: sender.title)!, forKey: "Order")
    }
    
    @IBAction func unhideMiddle(_ sender: NSButton) {
        splitView.setPosition(splitView.minPossiblePositionOfDivider(at: 1), ofDividerAt: 1)
    }
    
    @IBAction func logout(_ sender: NSButton) {
        self.performSegue(withIdentifier: NSStoryboardSegue.Identifier(rawValue: "Log out"), sender: self)
        for i in NSApplication.shared.windows {
            if !["Login", "Whitelist", "About", "Bug Reporter"].contains(i.title) {
                i.orderOut(self)
            }
        }
        let menu = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!.submenu!
        if let item = menu.item(withTitle: "Create Source Item") {
            menu.removeItem(item)
        }
        logged_in = false
    }
    
//    override func flagsChanged(theEvent: NSEvent) {
//        let menuItem = NSApplication.sharedApplication().mainMenu!.itemWithTitle("Find my EA")?.submenu?.itemWithTitle("Whitelist")
//        menuItem!.hidden = !NSEvent.modifierFlags().contains(.AlternateKeyMask)
//    }
    
    // Update Download. This is a special class of circular progress indicator which I designed.

    var updateProgress: CGFloat = 0.0 {
        didSet {
            updatePercentage.stringValue = "\(Int(updateProgress * 100))%"
            updateDownloadProgress.percentage = updateProgress
        }
    }
    
    // When the update has been downloaded
    
    func updateFinished() {
        updateDownloadBackground.isHidden = true
        updateDownloadProgress.isHidden = true
        logoImage.isHidden = false
        updateProgressText.stringValue = "Update downloaded."
        updatePercentage.stringValue = ""
        let alert = NSAlert()
        alert.messageText = "I'm ready."
        alert.informativeText = "Would you like to update right now?"
        alert.addButton(withTitle: "Install Now").keyEquivalent = "\r"
        alert.addButton(withTitle: "Later")
        customizeAlert(alert, height: 0, barPosition: 0)
        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
//            let command = Terminal(launchPath: "/bin/sh", arguments: ["-c", "sleep 1; open \"\(appPath)\""])
            let command = Terminal(launchPath: "/usr/bin/open", arguments: [NSTemporaryDirectory() + "Find my EA.pkg"])
            command.execUntilExit()
            NSApplication.shared.terminate(0)
        } else {
            (NSApplication.shared.delegate as! AppDelegate).installUpdate.isHidden = false
            (NSApplication.shared.delegate as! AppDelegate).updateItem.isEnabled = false
        }
        updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
    }
    
    @IBAction func installUpdate(_ sender: NSButton) {
        let command = Terminal(launchPath: "/usr/bin/open", arguments: [NSTemporaryDirectory() + "Find my EA.pkg"])
        command.execUntilExit()
        NSApplication.shared.terminate(0)
    }
    
    func startUpdate() {
        updateProgressText.stringValue = "Preparing update..."
        Terminal().deleteFileWithPath(NSTemporaryDirectory() + "Find my EA.pkg")
        requestManager?.delegate = self
        updateDownloadProgress.percentage = 0
        let menu = NSMenu(title: "Update")
        menu.addItem(withTitle: "Cancel Download", action: #selector(ViewController.cancelUpdate), keyEquivalent: "")
        updateDownloadProgress.menu = menu
        requestManager?.addRequestForDownloadFile(atRemotePath: "../downloads/Find my EA.pkg", toLocalPath: NSTemporaryDirectory() + "Find my EA.pkg")
        requestManager?.startProcessingRequests()
        let menubar = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!
        menubar.submenu?.item(withTitle: "Check for Updates...")?.isEnabled = false
    }
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didCompletePercent percent: Float, forRequest request: GRRequestProtocol!) {
        updateProgress = CGFloat(percent)
        logoImage.isHidden = true
        updateDownloadProgress.isHidden = false
        updateDownloadBackground.isHidden = false
        updateProgressText.stringValue = "Downloading update..."
    }
    
    func requestsManager(_ requestsManager: GRRequestsManagerProtocol!, didCompleteDownloadRequest request: GRDataExchangeRequestProtocol!) {
        updateFinished()
    }
    
    @objc func cancelUpdate() {
//        updateDownload?.cancel()
        updateDownloadBackground.isHidden = true
        updateDownloadProgress.isHidden = true
        updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
        logoImage.isHidden = false
        updatePercentage.stringValue = ""
        requestManager?.stopAndCancelAllRequests()
        let menu = NSApplication.shared.mainMenu!.item(withTitle: "Find my EA")!
        menu.submenu?.item(withTitle: "Check for Updates...")?.isEnabled = true
    }
    
    // Universal Favorite Count Update
    
    var shouldUpdateFavorites = true
    
    func favoriteUpdate() {
        
        if appstudentID == "" {
            return
        }
        
        let url = URL(string: serverAddress + "tenicCore/FavoriteUpdate.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "id=\(appstudentID == "" ? "_" : appstudentID)".data(using: .utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil || data == nil || self.loadImage.isAnimating || !self.shouldUpdateFavorites {
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.favoriteUpdate()
                }
                return
            }
            
            do {
                if try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary as? [String: String] == nil {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.favoriteUpdate()
                    }
                    return
                }
                let data = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary as! [String: String]
                DispatchQueue.main.async {
                    
                    for i in 0..<self.visibleEAs.count {
                        if /*self.visibleEAs[i].favorites != data[self.visibleEAs[i].name]! &&*/ self.shouldUpdateFavorites {
                            self.responsive = false
                            self.visibleEAs[i].favorites = data[self.visibleEAs[i].name]!
                            self.responsive = true

                            if self.EADetailTable.view(atColumn: 0, row: i, makeIfNecessary: false) as? EAInfo == nil {break}
                            
                            let cell = self.EADetailTable.view(atColumn: 0, row: i, makeIfNecessary: false) as! EAInfo
                            // Update the number of likes and whether the user liked the EA
                            if data[self.visibleEAs[i].name]! == "" {
                                cell.numberOfLikes.integerValue = 0; cell.like.image = cell.backgroundStyle == .dark ? #imageLiteral(resourceName: "Favorite_dark") :#imageLiteral(resourceName: "Favorite_outline")
                                if self.EATableView.selectedRow == 3 {
                                    self.EADetailTable.removeRows(at: IndexSet(integer: i), withAnimation: NSTableView.AnimationOptions.effectFade)
                                }
                                if #available(OSX 10.12.2, *), i == self.EADetailTable.selectedRow {
                                    (self.touchBar?.item(forIdentifier: NSTouchBarItem.Identifier(rawValue: "Button: Like"))?.view as? NSButton)?.image = #imageLiteral(resourceName: "favorite_small_dark")
                                }
                            } else {
                                cell.numberOfLikes.integerValue = data[self.visibleEAs[i].name]!.components(separatedBy: " | ").count
                                cell.like.image = data[self.visibleEAs[i].name]!.contains(appstudentID) && appstudentID != "" ? #imageLiteral(resourceName: "Favorite") : (cell.backgroundStyle == .dark ? #imageLiteral(resourceName: "Favorite_dark") : #imageLiteral(resourceName: "Favorite_outline"))
                                if self.EATableView.selectedRow == 3 && !data[self.visibleEAs[i].name]!.contains(appstudentID) {
                                    self.EADetailTable.removeRows(at: IndexSet(integer: i), withAnimation: NSTableView.AnimationOptions.effectFade)
                                }
                                if #available(OSX 10.12.2, *), self.EADetailTable.selectedRow == i {
                                    (self.touchBar?.item(forIdentifier: .init(rawValue: "Button: Like"))?.view as? NSButton)?.image = data[self.visibleEAs[i].name]!.contains(appstudentID) ? #imageLiteral(resourceName: "Favorite_small") : #imageLiteral(resourceName: "favorite_small_dark")
                                }
                            }
                        }
                    }
                    self.responsive = false
                    
                    for i in 0..<self.EAs["All EAs"]!.count {
                        self.EAs["All EAs"]![i].favorites = data[self.EAs["All EAs"]![i].name]!
                    }
                    
                    if appstudentID != "" && self.firstLogin {
                        self.EAs["EAs Pending"] = self.EAs["All EAs"]!.filter {$0.availability == "Pending"}
                        (self.EATableView.view(atColumn: 0, row: 1, makeIfNecessary: false) as! EACellView)
                        .digit = self.EAs["EAs Pending"]!.count
                        self.EAs["EAs I Joined"] = self.EAs["All EAs"]!.filter {$0.availability == "Approved"}
                        (self.EATableView.view(atColumn: 0, row: 2, makeIfNecessary: false) as! EACellView)
                        .digit = self.EAs["EAs I Joined"]!.count
                        
                        self.EAs["Favorites"] = self.EAs["All EAs"]!.filter {$0.favorites.contains(appstudentID)}
                        (self.EATableView.view(atColumn: 0, row: 3, makeIfNecessary: false) as! EACellView)
                        .digit = self.EAs["Favorites"]!.count
                    }
                    self.responsive = true
                    
                    if appstudentID != "" && self.firstLogin {
                        if self.EATableView.selectedRow == 1 {
                            self.visibleEAs = self.EAs["EAs Pending"]!
                        } else if self.EATableView.selectedRow == 2 {
                            self.visibleEAs = self.EAs["EAs I Joined"]!
                        } else if self.EATableView.selectedRow == 3 {
                            self.visibleEAs = self.EAs["Favorites"]!
                        }
                        self.firstLogin = false
                    }
                    
                    switch self.EATableView.selectedRow {
                    case 0:
                        let noun = self.EAs["All EAs"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(self.EAs["All EAs"]!.count) " + noun + " in total."
                    case 1:
                        let noun = self.EAs["EAs Pending"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(self.EAs["EAs Pending"]!.count) " + noun + " pending."
                    case 2:
                        let noun = self.EAs["EAs I Joined"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "\(self.EAs["EAs I Joined"]!.count) " + noun + " joined."
                    case 3:
                        let noun = self.EAs["Favorites"]!.count == 1 ? "EA" : "EAs"
                        self.bottomInfoLabel.stringValue = "You have \(self.EAs["Favorites"]!.count) favorite " + noun + "."
                    default:
                        break
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.favoriteUpdate()
                    }
                }
            } catch {
                print(String(data: data!, encoding: .utf8) ?? "No string data")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.favoriteUpdate()
                }
            }
        }
        task.resume()
    }

}





// Additional functions and classes


func customizeAlert(_ alert: NSAlert, height: CGFloat, barPosition: CGFloat) {
//    alert.window.styleMask |= NSFullSizeContentViewWindowMask
    object_setClass(alert.window, NonResizableWindow.classForCoder())
    (alert.window as! NonResizableWindow).initialize()
    alert.window.titlebarAppearsTransparent = true
    alert.window.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    alert.window.backgroundColor = NSColor.white
    alert.window.contentView?.wantsLayer = true
    
    let textSize = calculateHeightForFont(NSFont.systemFont(ofSize: 11), text: alert.informativeText, width: 290, label: true)
    print(alert.informativeText)
    print("calculated size: \(textSize)")
    
    let bar = NSImageView(frame: NSMakeRect(0, 90 + (textSize < 41 ? 41 : textSize) + barPosition, alert.window.frame.width, 23))
    bar.imageScaling = .scaleAxesIndependently
    bar.alphaValue = 1
    if UserDefaults.standard.bool(forKey: "Blue Theme") {
        alert.window.contentView?.layer?.backgroundColor = NSColor(red: 0.17, green: 0.38, blue: 0.51, alpha: 1).cgColor
        bar.image = #imageLiteral(resourceName: "top_gradient_blue")

    } else {
        alert.window.contentView?.layer?.backgroundColor = NSColor(red: 0.55, green: 0.12, blue: 0.1, alpha: 1).cgColor
        bar.image = #imageLiteral(resourceName: "top_gradient")
    }
    alert.window.setFrame(NSRect(origin: alert.window.frame.origin, size: NSMakeSize(alert.window.contentView!.frame.width, alert.window.contentView!.frame.height + 22)), display: true)
    
    alert.window.maxSize = alert.window.contentView!.frame.size
    alert.window.maxSize.height += height
    alert.window.minSize = alert.window.maxSize
    alert.window.maxSize.height -= 15
    
    print(alert.window.frame)
    
    alert.window.contentView?.addSubview(bar)
    for i in alert.window.contentView!.subviews {
        i.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        if let tmp = i as? NSTextField {
            tmp.textColor = NSColor(red: 0.98, green: 0.92, blue: 0.6, alpha: 1)
            var att = tmp.attributedStringValue.attributes(at: 0, effectiveRange: nil)
            att[NSAttributedStringKey.foregroundColor] = tmp.textColor!
            tmp.attributedStringValue = NSAttributedString(string: tmp.stringValue, attributes: att)
        }
    }

}

class NonResizableWindow: NSWindow {
    override var isResizable: Bool {
        return false
    }
    
    func initialize() -> NSRect {
        self.styleMask.insert(NSWindow.StyleMask.fullSizeContentView)
        return self.frame
    }
}

func firstAlertLayout(_ alert: NSAlert) {
    for i in alert.window.contentView!.subviews {
        if let _ = i as? NSButton {
            
        } else {
            i.setFrameOrigin(NSMakePoint(i.frame.origin.x, i.frame.origin.y - 23))
        }
        i.appearance = NSAppearance(named: NSAppearance.Name.aqua)
    }
    hasRunAlert = true
}

class AlertWindow: NSWindow {
    
    override func awakeFromNib() {
        self.styleMask.remove(NSWindow.StyleMask.resizable)
    }
    
    override var isResizable: Bool {
        return false
    }
}

class SplitView: NSSplitView {
    override var dividerColor: NSColor {
        if UserDefaults.standard.bool(forKey: "Blue Theme") {
            return NSColor(red: 0.8, green: 0.88, blue: 1, alpha: 1)
        } else {
            return NSColor(red: 1, green: 0.8, blue: 0.79, alpha: 1)
        }
    }
    override var dividerThickness: CGFloat {
        self.dividerStyle = .thin
        return UserDefaults.standard.bool(forKey: "Blue Theme") ? 2 : 1
    }
}

// Below is a comprehensive list of all the animations included in Find my EA.

let database = [
    "Books": (130, 62),
    "Cycling": (63, 54),
    "Atom": (88, 46),
    "Wheel": (98, 24),
    "Earth": (119, 30),
    "Windmill": (224, 45),
    "Tree": (120, 44),
    "Mind": (64, 35),
    "Search": (174, 74),
    "Rocket": (167, 30),
    "Cloud Sync": (108, 19),
    "Chemistry": (363, 67),
    "Camera": (17, 12),
    "Refresh": (114, 25),
    "Sliders": (170, 51),
    "Background": (223, 82),
    "Gears": (62, 16),
    "Recorder": (94, 48),
    "Drink": (54, 32),
    "Windmill2": (136, 29),
    "Sun": (74, 15),
    "Fingerprint": (166, 59),
    "Writing": (178, 92),
    "Calliper": (50, 12),
    "Surfing": (197, 52),
//    "Tree Growth": (183, 90) I've taken this out just to save some space
    ]

let database_special = ["Cloud Sync", "Background"]

class LoadImage: NSImageView {
    
    var isAnimating = false
    var imageName = ""
    var max = 0
    var breakpoint = 0
    var fps = 25.0
    
    override var mouseDownCanMoveWindow: Bool {
        return true
    }
    
    var currentThread: Thread?
    
    let resourcePath = Bundle.main.resourcePath!
    
    func startAnimation(_ image: String) {
        if currentThread != nil && !currentThread!.isCancelled {return}
        self.image = nil
        if image == "Random" || !database.keys.contains(image) {
            let num = arc4random_uniform(UInt32(database.count - 1 - database_special.count))
            self.imageName = Array(database.keys).filter({$0 != imageName && !database_special.contains($0)})[Int(num)]
//            self.imageName = "Tree Growth"
        } else {
            self.imageName = image
        }
        if !database.keys.contains(imageName) {
            imageName = "Cloud Sync"
        }
        max = database[imageName]!.0
        breakpoint = database[imageName]!.1
        self.isHidden = false
        isAnimating = true
        currentThread = Thread(target: self, selector: #selector(LoadImage.loop), object: nil)
//        currentThread.stackSize = 1048576
        currentThread!.start()
    }
    
    func stopAnimation() {
        isAnimating = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.currentThread?.cancel()
        }
    }
    
    @objc func loop() {
        var currentFrame = 0
        let imageData = NSData.data(withCompressedData: (animationPack[NSString(string: imageName).aes256Encrypt(withKey: AESKey)]! as NSData).aes256Decrypt(withKey: AESKey)) as! Data
        let sequence = NSKeyedUnarchiver.unarchiveObject(with: imageData) as! [Data]
        while isAnimating {
//            let name = imageName + "_" + String(format: "%03d", currentFrame) + ".png"
//            let tmp = NSImage(contentsOfFile: resourcePath + "/" + imageName + "/" + name)
            DispatchQueue.main.async {
                self.image = NSImage(data: sequence[currentFrame])
            }
            currentFrame = currentFrame < max ? currentFrame + 1 : breakpoint
            Thread.sleep(forTimeInterval: 1 / fps - 0.005)
        }
        self.isHidden = true
        return
    }
}

var isEATableViewfocused = true {
didSet {
    print(isEATableViewfocused)
}
}

class EATable: NSTableView {
    override func becomeFirstResponder() -> Bool {
        isEATableViewfocused = true
        return true
    }
    override func resignFirstResponder() -> Bool {
        isEATableViewfocused = false
        return true
    }
    
}
