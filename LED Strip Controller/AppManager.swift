//
//  AppManager.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/27/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class AppManager {
    static var activity: NSObjectProtocol?
    
    static func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.terminate(self)
    }
    
    static func quitApp() {
        NSApplication.shared.terminate(self)
    }
    
    // disables app nap, change options to .userInitiated to disable sleep as well
    static func disableSleep() {
        activity = ProcessInfo().beginActivity(options: .userInitiatedAllowingIdleSystemSleep, reason: "Actively sending colors to lights")
    }
    
    static func enableSleep() {
        if let processInfo = activity {
            ProcessInfo().endActivity(processInfo)
        }
    }
}
