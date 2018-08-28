//
//  ForgotPassword.swift
//  Found my EA
//
//  Created by Jia Rui Shan on 1/28/17.
//  Copyright © 2017 Jerry Shan. All rights reserved.
//

// This view controller is responsible for the forgot password view.

import Cocoa

class ForgotPassword: NSViewController, NSTextFieldDelegate {

    @IBOutlet weak var verticalBanner: NSView!
    @IBOutlet weak var version: NSTextField!
    @IBOutlet weak var code: NSTextField!
    @IBOutlet weak var resetButton: NSButton!
    @IBOutlet weak var resetSpinner: NSProgressIndicator!
    @IBOutlet weak var startView: NSView!
    @IBOutlet weak var account: NSTextField!
    @IBOutlet weak var accountDescription: NSTextField!
    @IBOutlet weak var continueResetButton: NSButton!
    @IBOutlet weak var resetView: NSView!
    @IBOutlet weak var finishView: NSView!
    @IBOutlet weak var emailSent: NSTextField!
    
    @IBOutlet weak var closeButton: CloseButton!
    
    var verificationCode = ""
    var email = ""
    
    var validAccount = false {
        didSet {
            continueResetButton.isEnabled = validAccount
        }
    }
    
    let d = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()
        verticalBanner.wantsLayer = true
        var themeColor = NSColor(red: 210/255, green: 41/255, blue: 33/255, alpha: 1)
        closeButton.isHidden = true
        if d.bool(forKey: "Blue Theme") {
            themeColor = NSColor(red: 30/255, green: 140/255, blue: 220/255, alpha: 1)
            closeButton.isHidden = false
            continueResetButton.image = #imageLiteral(resourceName: "continueLogin_blue")
            resetButton.image = #imageLiteral(resourceName: "continueLogin_blue")
        }
        
        verticalBanner.layer?.backgroundColor = themeColor.cgColor
        
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as! String
        version.stringValue = currentVersion
        version.isHidden = true
        account.stringValue = d.string(forKey: "ID") ?? ""
        controlTextDidChange(Notification(name: Notification.Name(rawValue: ""), object: account))
    }
    
    @IBAction func continueReset(_ sender: NSButton) {
        startView.layer?.removeAllAnimations()
        resetView.layer?.removeAllAnimations()
        
        let animation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.fromValue = 0
        animation.toValue = -30
        animation.duration = 0.25
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        startView.layer?.add(animation, forKey: "Move")
        
        let dissolve = CABasicAnimation(keyPath: "opacity")
        startView.alphaValue = 0
        dissolve.fromValue = 1
        dissolve.toValue = 0
        dissolve.duration = 0.2
        dissolve.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
        startView.layer?.add(dissolve, forKey: "Dissolve")
        
        animation.fromValue = 30
        animation.toValue = 0
        animation.isRemovedOnCompletion = false
        resetView.layer?.add(animation, forKey: "Reset Appear")
        
        resetView.alphaValue = 1
        resetView.isHidden = false
        dissolve.fromValue = 0
        dissolve.toValue = 1
        resetView.layer?.add(dissolve, forKey: "Appear")

        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.startView.isHidden = true
            self.code.becomeFirstResponder()
        }
    }
    
    @IBAction func sendCode(_ sender: NSButton) {
        let url = URL(string: serverAddress + "tenicCore/VerificationCode.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        var code = ""
        let chars = ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
            "r", "s", "t", "u", "v", "w", "x", "y", "z", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
        for _ in 0..<6 {
            code += chars[Int(arc4random_uniform(UInt32(chars.count)))]
        }
        self.verificationCode = code
        let postString = "email=\(email)&code=\(code)"
        print(code)
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print(error!)
            } else {
                DispatchQueue.main.async {
                    sender.isEnabled = false
                    self.code.isEnabled = true
                    self.emailSent.isHidden = false
                }
            }
        }
        task.resume()
    }
    
    func verifyAccount(_ id: String) {
        accountDescription.stringValue = "Verifying account..."
        let url = URL(string: serverAddress + "tenicCore/UserAuthentication.php")
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        let postString = "username=\(id)&password=&version=x"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        let task = URLSession.shared.dataTask(with: request, completionHandler: {
            data, reponse, error in
            if error != nil {
                print(error!)
                DispatchQueue.main.async {
                    self.accountDescription.stringValue = "You are offline."
                }
                return
            }
            do {
                let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSDictionary as! [String:String]
                if json["status"]! == "failure" && json["message"] == "Login error!" {
                    DispatchQueue.main.async {
                        self.validAccount = false
                        self.accountDescription.stringValue = "✘ Account does not exist. Please recheck the ID you have entered."
                    }
                } else {
                    DispatchQueue.main.async {
                        self.validAccount = true
                        self.email = json["email"]!.contains("@") ? json["email"]! : regularizeID(id)! + "@mybcis.cn"
                        self.accountDescription.stringValue = "Account exists ✔\nEmail: \(self.email)"
                    }
                }
            } catch {
                
            }
        }) 
        task.resume()
    }
    
    @IBAction func resetPassword(_ sender: NSButton) {
        resetSpinner.startAnimation(nil)
        sender.isHidden = true
        let url = URL(string: serverAddress + "tenicCore/ResetPassword.php")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let postString = "username=\(account.stringValue)&old= &new=bcis&override=true"
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) {
            data, response, error in
            if error != nil {
                print(error!)
                DispatchQueue.main.async {
                    self.resetSpinner.stopAnimation(nil)
                    sender.isHidden = false
                }
                return
            } else {
                print(String(data: data!, encoding: String.Encoding.utf8)!)
                DispatchQueue.main.async {
                    self.resetView.isHidden = true
                    self.finishView.isHidden = false
                    self.view.window?.hidesOnDeactivate = true
                    UserDefaults.standard.set("bcis".data(using: String.Encoding.utf8), forKey: "Password")
                }
            }
        }
        task.resume()

    }
    
    override func controlTextDidChange(_ obj: Notification) {
        let textfield = obj.object as! NSTextField
        if textfield == account {
            if let id = regularizeID(account.stringValue) {
                verifyAccount(id)
            } else {
                validAccount = false
                accountDescription.stringValue = ""
            }
        } else {
            resetButton.isEnabled = code.stringValue.caseInsensitiveCompare(verificationCode) == .orderedSame && code.stringValue != ""
        }
    }
    
    @IBAction func endEditingCode(_ sender: NSTextField) {
        self.resetPassword(resetButton)
    }
    
}
