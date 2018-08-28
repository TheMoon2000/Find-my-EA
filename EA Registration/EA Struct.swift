//
//  EA Info.swift
//  EA Registration
//
//  Created by Jia Rui Shan on 12/3/16.
//  Copyright © 2016 Jerry Shan. All rights reserved.
//

import Cocoa

struct EA {
    var name = ""
    var description = ""
    var leader = ""
    var supervisor = ""
    var id = ""
    var location = ""
    var time = ""
    var approval = ""
    var message = ""
    var age = " | "
    var color = ""
    var max = ""
    var dates = ""
    var startDate = ""
    var endDate = ""
    var prompt = ""
    var type = ""
    var frequency = 4
    var participants = 0
    var favorites = ""
    
    var availability = ""
    
    var email: String {
        let idArray = id.components(separatedBy: ", ").filter {$0 != "" && !isTeacher($0)}
        return idArray.map({$0.characters.count == 8 ? "20" + $0 : $0}).joined(separator: ", ") + "@mybcis.cn"
    }
    
    init(EA_Name: String, description: String, date: String, leader: String, type: String, id: String, supervisor: String, location: String, approval: String, age: String, max: String, dates: String, startDate: String, endDate: String, prompt: String, frequency: Int, favorites: String) {
        name = EA_Name
        self.description = description
        self.time = date
        self.leader = leader
        self.type = type
        self.supervisor = supervisor
        self.id = id
        self.location = location
        self.approval = approval
        self.age = age
        self.max = max
        self.dates = dates
        self.startDate = startDate
        self.endDate = endDate
        self.prompt = prompt
        self.frequency = frequency
        self.favorites = favorites
    }
}

func launchDaemon() {
    let command = Terminal(launchPath: "/usr/bin/killall", arguments: ["Find my EA Messenger"])
    command.execUntilExit()
    command.launchPath = "/usr/bin/open"
    command.arguments = [messengerPath]
    command.exec()
    NSApplication.shared.activate(ignoringOtherApps: false)
}
