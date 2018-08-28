//
//  ViewController.swift
//  Whitelist
//
//  Created by Jia Rui Shan on 7/26/16.
//  Copyright © 2016 Tenic. All rights reserved.
//

import Cocoa

var whitelistViewController = WhitelistViewController()

class WhitelistViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate {

    @IBOutlet var tableView: NSTableView!
    @IBOutlet weak var newIP: NSTextField!
    @IBOutlet weak var newDomain: NSTextField!
    @IBOutlet weak var ipColumn: NSTableColumn!
    @IBOutlet weak var domainColumn: NSTableColumn!
    @IBOutlet weak var addButton: NSButton!
    @IBOutlet weak var activated: ITSwitch!
    
    var sortedKeys = [String]()
    
    let d = UserDefaults.standard
    
    var animation = false
    var domainDictionary: [String: String] = [:] {
        didSet {
            sortedKeys = Array(domainDictionary.keys).sorted(by: {$0 < $1})
            if !animation {
                tableView.reloadData()
            }
            saveToFile()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        whitelistViewController = self
        let nib = NSNib(nibNamed: NSNib.Name(rawValue: "DataCell"), bundle: Bundle.main)
        tableView.register(nib!, forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"))
        ipColumn.isEditable = true
        domainColumn.isEditable = true
        loadFromFile()
        activated.checked = d.bool(forKey: "Enabled")

    }

    var filePath: String {
        var posix = NSString(string: "~/Library/Application Support/Whitelist")
        posix = posix.expandingTildeInPath as NSString
//        Terminal(launchPath: "/bin/sh", arguments: ["-c", "mkdir '" + (posix as String) + "'"]).execUntilExit()
        return posix as String
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return domainDictionary.count
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "cell"), owner: self) as! DataCell
        if (tableColumn?.title == "Domain") {
            cell.cellTitle.stringValue = sortedKeys[row]
        } else {
            cell.cellTitle.stringValue = domainDictionary[sortedKeys[row]]!
        }
        
        return cell
    }

    @IBAction func apply(_ sender: NSButton) {
        //let filemanager = NSFileManager()
        if (activated.checked) {
            do {
            var string = try String(contentsOfFile: "/etc/hosts", encoding: String.Encoding.utf8)
                if string.contains("\n#Whitelist\n") {
                    let originalPart = string.components(separatedBy: "\n#Whitelist\n")[0]
                    var newPart = "\n"
                    for i in Array(domainDictionary.keys) {
                        newPart.append("\(domainDictionary[i]!)\t\(i)\n")
                    }
                    string = originalPart + "\n#Whitelist\n" + newPart
                } else {
                    string += string.hasSuffix("\n\n") ? "" : "\n\n"
                    string += "#Whitelist\n"
                    for i in Array(domainDictionary.keys) {
                        string.append("\n\(domainDictionary[i]!)\t\(i)")
                    }
                }
                doScriptWithAdmin("echo '\(string)' > /etc/hosts")
            } catch let error as NSError {
                print(error)
            }
        } else {
            do {
                var string = try String(contentsOfFile: "/etc/hosts", encoding: String.Encoding.utf8)
                string = string.components(separatedBy: "\n#Whitelist\n")[0]
                doScriptWithAdmin("echo '\(string)' > /etc/hosts")
            } catch {
                
            }
        }
    }
    
    @IBAction func addPair(_ sender: NSButton) {
        if (!Array(domainDictionary.keys).contains(newDomain.stringValue)) {
            domainDictionary[newDomain.stringValue] = newIP.stringValue
            tableView.reloadData()
            tableView.selectRowIndexes(IndexSet(integer: sortedKeys.index(of: newDomain.stringValue)!), byExtendingSelection: false)
            tableView.scrollRowToVisible(tableView.selectedRow)
            newIP.stringValue = ""
            newDomain.stringValue = ""
            newIP.becomeFirstResponder()
            addButton.isEnabled = false
        }
    }
    
    func updateValue(_ title: String) {
        let row = tableView.selectedRow
        let selectedDomainCell = tableView.view(atColumn: tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Domain")), row: row, makeIfNecessary: false) as! DataCell
        print("title: \(title)")
        print("domain title: \(selectedDomainCell.cellTitle.stringValue)")
        let ipCell = tableView.view(atColumn: tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue:"IP")), row: row, makeIfNecessary: false) as! DataCell
        let oldValue = sortedKeys[row]
        animation = true
        if sortedKeys.contains(selectedDomainCell.cellTitle.stringValue) {
            // User changed the IP or changed a domain name to one that already exists
            if title == selectedDomainCell.cellTitle.stringValue {
                selectedDomainCell.cellTitle.stringValue = oldValue
                return
            }
        } else {
            domainDictionary.removeValue(forKey: oldValue)
        }
        domainDictionary[selectedDomainCell.cellTitle.stringValue] = ipCell.cellTitle.stringValue
//        print(sortedKeys)
        animation = false
        tableView.reloadData()
        tableView.selectRowIndexes(IndexSet(integer: sortedKeys.index(of: selectedDomainCell.cellTitle.stringValue)!), byExtendingSelection: false)
        tableView.scrollRowToVisible(tableView.selectedRow)
    }
    
    @IBAction func toggle(_ sender: ITSwitch) {
        d.set(sender.checked, forKey: "Enabled")
    }
    
    func deleteCurrentEntry() {
        if tableView.selectedRow == -1 {return}
        
        if d.integer(forKey: "Whitelist Warning") == -1 && !NSEvent.modifierFlags.contains(NSEvent.ModifierFlags.option) {                self.animation = true
            for i in self.tableView.selectedRowIndexes {
                let domain = self.tableView.view(atColumn: self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Domain")), row: i, makeIfNecessary: false) as! DataCell
                self.domainDictionary.removeValue(forKey: domain.cellTitle.stringValue)
            }
            self.tableView.removeRows(at: self.tableView.selectedRowIndexes, withAnimation: NSTableView.AnimationOptions.slideUp)
            self.animation = false
            return
        }
        
        let alert = NSAlert()
        let noun = tableView.selectedRowIndexes.count == 1 ? "row" : "rows"
        alert.messageText = "You are about to delete \(tableView.selectedRowIndexes.count) " + noun + "."
        alert.informativeText = "These domain entries will be permanently deleted from your record. However, you still need to press \"Apply\" to activate this change."
        alert.addButton(withTitle: "Proceed").keyEquivalent = "\r"
        alert.addButton(withTitle: "Cancel")
        alert.showsSuppressionButton = d.integer(forKey: "Whitelist Warning") != 0
        alert.suppressionButton?.objectValue = d.integer(forKey: "Whitelist Warning") == -1
        
        alert.beginSheetModal(for: view.window!) {response -> Void in
            if response == NSApplication.ModalResponse.alertFirstButtonReturn {
                self.animation = true
                for i in self.tableView.selectedRowIndexes {
                    let domain = self.tableView.view(atColumn: self.tableView.column(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "Domain")), row: i, makeIfNecessary: false) as! DataCell
                    self.domainDictionary.removeValue(forKey: domain.cellTitle.stringValue)
                }
                self.tableView.removeRows(at: self.tableView.selectedRowIndexes, withAnimation: NSTableView.AnimationOptions.slideUp)
                self.animation = false
                
            }
            self.d.set(alert.showsSuppressionButton ? (alert.suppressionButton!.state.rawValue == 1 ? -1 : 1) : 1, forKey: "Whitelist Warning")
        }
        
    }

    override func controlTextDidChange(_ obj: Notification) {
        addButton.isEnabled = newDomain.stringValue != "" && newIP.stringValue.components(separatedBy: ".").count == 4
    }
    
    func compare(_ sender: NSTableColumn) {
        print("order")
    }
    
    func compareDomain(_ sender: NSTableColumn) {
        print("order domain")
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
//    override func viewWillDisappear() {
//        saveToFile()
//    }
    
    func saveToFile() {
        Terminal(launchPath: "/bin/mkdir", arguments: ["-p", filePath]).execUntilExit()
        NSKeyedArchiver.archiveRootObject(domainDictionary, toFile: filePath + "/iplist.wlist")
    }
    
    func loadFromFile() {
        domainDictionary = NSKeyedUnarchiver.unarchiveObject(withFile: filePath + "/iplist.wlist") as? [String:String] ?? [String:String]()
    }
    
    func doScriptWithAdmin(_ inScript:String){
        let script = "do shell script \"\(inScript)\" with administrator privileges"
        let appleScript = NSAppleScript(source: script)
       appleScript!.executeAndReturnError(nil)
    }

}

