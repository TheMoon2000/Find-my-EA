//
//  CheckForUpdates.swift
//  Found my EA
//
//  Created by Jia Rui Shan on 12/30/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

// This file is responsible for the check-for-update function.

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


var ischecking = false

func checkForUpdates(_ active: Bool) {
    if !logged_in {return}
    if ischecking {return}
    ischecking = true
    
    let url = URL(string: serverAddress + "tenicCore/CheckUpdate.php")!
    
    let alert = NSAlert()
    
    let ap = NSApplication.shared.delegate as! AppDelegate

    let task = URLSession.shared.dataTask(with: url) {
        data, response, error in
        if error != nil {
            print("error=\(error!)")
            if !active {return}
            DispatchQueue.main.async {
                ap.viewController?.updateDownloadProgress.isHidden = true
                ap.viewController?.updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
                alert.messageText = "Connection Error!"
                alert.informativeText = "How am I suppose to check for updates when I'm offline?"
                alert.addButton(withTitle: "OK").keyEquivalent = "\r"
                if !hasRunAlert {firstAlertLayout(alert)}
                customizeAlert(alert, height: 0, barPosition: 0)
                alert.runModal()
            }
            return
        }
        do {
            ischecking = false
            let json = try JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as! NSArray
            var updateInfo = json[0] as! [String:String]
            let currentVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as! String
            if Int(updateInfo["Version"]!) > Int(currentVersion) {
                DispatchQueue.main.async {
                    alert.messageText = "An Update is Available!"
                    alert.informativeText = updateInfo["Description"]!
                    alert.addButton(withTitle: "Update").keyEquivalent = "\r"
                    if updateInfo["Importance"]! == "0"{
                        alert.addButton(withTitle: "Not Now")
                    }
                    if !hasRunAlert {firstAlertLayout(alert)}
                    customizeAlert(alert, height: 0, barPosition: 0)
                    ap.viewController?.updateDownloadProgress.isHidden = true
                    ap.viewController?.updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
                    if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
                        ap.viewController?.startUpdate()
                    }
                }
            } else if active {
                DispatchQueue.main.async {
                    if !hasRunAlert {firstAlertLayout(alert)} else {
                        print(hasRunAlert)
                    }
                    alert.addButton(withTitle: "OK").keyEquivalent = "\r"
                    alert.messageText = "No Update Available :("
                    alert.informativeText = "This is currently the newest version of Find my EA."
                    customizeAlert(alert, height: 0, barPosition: 0)
                    ap.viewController?.updateDownloadProgress.isHidden = true
                    ap.viewController?.updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
                    alert.runModal()
                }
            }
            
        } catch let err as NSError {
            DispatchQueue.main.async {
                ap.viewController?.updateDownloadProgress.isHidden = true
                ap.viewController?.updateProgressText.stringValue = "Find an EA, find a passion, and find a dream."
                alert.messageText = "Connection Error!"
                alert.informativeText = "How am I suppose to check for updates when I'm offline?"
                alert.addButton(withTitle: "OK").keyEquivalent = "\r"
                if !hasRunAlert {firstAlertLayout(alert)}
                customizeAlert(alert, height: 0, barPosition: 0)
                alert.runModal()
            }
            print(err)

        }
        return
    }
    task.resume()
    
}
