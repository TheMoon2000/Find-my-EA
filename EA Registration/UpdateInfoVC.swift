//
//  UpdateInfoVC.swift
//  Found my EA
//
//  Created by Jia Rui Shan on 08/06/2017.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

// This view controller is responsible for the view that changes the user's displayed name and advisory (or email if the user is a teacher)

import Cocoa

class UpdateInfoVC: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var verticalBanner: NSView!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var closeButton: CloseButton!
    
    @IBOutlet weak var name: NSTextField!
    @IBOutlet weak var advisory: NSTextField!
    @IBOutlet weak var saveButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!
    @IBOutlet weak var warning: NSTextField!

    override func viewDidLoad() {
        if UserDefaults.standard.value(forKey: "Blue Theme") == nil {
            UserDefaults.standard.set(true, forKey: "Blue Theme")
        }
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        version.stringValue = currentVersion
        
        version.isHidden = true

        super.viewDidLoad()
        
        var themeColor = NSColor(red: 210/255, green: 41/255, blue: 33/255, alpha: 1)
        if UserDefaults.standard.bool(forKey: "Blue Theme") {
            themeColor = NSColor(red: 30/255, green: 140/255, blue: 220/255, alpha: 1)
            closeButton.isHidden = false
            saveButton.image = #imageLiteral(resourceName: "continueLogin_blue")
        } else {
            closeButton.isHidden = true
        }
        
        verticalBanner.wantsLayer = true
        verticalBanner.layer?.backgroundColor = themeColor.cgColor

        name.placeholderString = appfullname
        advisory.placeholderString = appadvisory
    }
    
    @IBAction func updateInfo(_ sender: NSButton) {
        warning.textColor = warningRed
        if name.stringValue == "" && advisory.stringValue == "" {
            warning.stringValue = "Fields cannot be blank"
        } else {
            warning.stringValue = ""
        }
        
        sender.isHidden = true
        spinner.startAnimation(nil)
        
        let url = URL(string: serverAddress + "tenicCore/UserUpdate.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        
        let email = isTeacher ? appadvisory : appstudentID + "@mybcis.cn"
        
        let postString = "id=\(appstudentID)&name=\(name.stringValue == "" ? name.placeholderString! : name.stringValue)&advisory=\(advisory.stringValue == "" ? advisory.placeholderString! : advisory.stringValue)&email=\(email)&host=\(Host.current().name!)&password=\(loginPass.encodedString)&admin=0"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            
            if error != nil {
                print(error!)
            }
            
            if String(data: data!, encoding: String.Encoding.utf8) == "successful" {
                DispatchQueue.main.async {
                    self.warning.textColor = warningGreen
                    self.warning.stringValue = "User info successfully updated."
                    
                    appfullname = self.name.stringValue == "" ? self.name.placeholderString! : self.name.stringValue
                    self.name.placeholderString = appfullname
                    
                    appadvisory = self.advisory.stringValue == "" ? self.advisory.placeholderString! : self.advisory.stringValue
                    self.advisory.placeholderString = appadvisory
                    
                    self.name.stringValue = ""
                    self.advisory.stringValue = ""
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {self.warning.stringValue = ""}
                    self.spinner.stopAnimation(nil)
                    sender.isHidden = false
                    sender.isEnabled = false
                }
            } else {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
                DispatchQueue.main.async {
                    self.warning.textColor = warningRed
                    self.warning.stringValue = "Unable to update data."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {self.warning.stringValue = ""}
                    self.spinner.stopAnimation(nil)
                    sender.isHidden = false
                }
            }
        }
        task.resume()
    }
    
    @IBAction func finishEditingName(_ sender: NSTextField) {
        advisory.becomeFirstResponder()
    }
    
    @IBAction func finishEditingAdvisory(_ sender: NSTextField) {
        if saveButton.isEnabled { self.updateInfo(saveButton)}
    }
    
    override func controlTextDidChange(_ obj: Notification) {
        saveButton.isEnabled = name.stringValue != "" || advisory.stringValue != ""
        if saveButton.isEnabled && !isTeacher && advisory.stringValue.contains("@") {
            saveButton.isEnabled = false
        }
    }

    
}
