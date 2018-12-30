//
//  AppManager.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/27/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class AppManager {
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
}
