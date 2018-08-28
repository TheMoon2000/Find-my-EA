//
//  MapViewController.swift
//  Find my EA
//
//  Created by Jia Rui Shan on 12/25/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa
import Quartz

class MapViewController: NSViewController {

    @IBOutlet weak var bannerImage: NSImageView!
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var mapImage: NSImageView!
    @IBOutlet weak var mapLabel: NSTextField!
    
    let sequence = NSKeyedUnarchiver.unarchiveObject(with: NSData.data(withCompressedData: (animationPack[NSString(string: "Campus Map").aes256Encrypt(withKey: AESKey)]! as NSData).aes256Decrypt(withKey: AESKey)) as! Data) as! [Data]
    
    var currentFloor = 1 {
        didSet {
            mapImage.image = NSImage(data: sequence[currentFloor])
            print(mapImage.image!.resolution)
            mapLabel.stringValue = ["Underground", "1st Floor", "2nd Floor", "3rd Floor", "4th Floor", "5th Floor"][currentFloor]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bannerImage.image = NSImage(named: NSImage.Name(rawValue: "top_gradient_blue.png"))
        scrollView.magnification = 1
        currentFloor = 1
    }
    
    @IBAction func upOneFloor(_ sender: NSButton) {
        if currentFloor < 5 {
            currentFloor += 1
        }
    }
    
    @IBAction func downOneFloor(_ sender: NSButton) {
        if currentFloor > 0 {
            currentFloor -= 1
        }
    }
    
}
