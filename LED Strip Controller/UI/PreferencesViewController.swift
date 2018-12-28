//
//  PreferencesViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class PreferencesViewController: NSViewController {

    @IBOutlet weak var outputDeviceList: NSPopUpButton!
    var deviceManager = OutputDeviceManager.shared
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        outputDeviceList.addItems(withTitles: OutputDeviceManager.getDevices())
    }
    
    @IBAction func outputDeviceSelected(_ sender: NSPopUpButton) {
        if !deviceManager.selectPort(withPath: sender.selectedItem?.title ?? "0") {
            outputDeviceList.selectItem(at: 0)
            return
        }
        
        print(deviceManager.port?.path)
        deviceManager.port?.open()
        deviceManager.sendByte(COLOR_BYTE)
        deviceManager.sendByte(0)
        deviceManager.sendByte(1)
        deviceManager.sendByte(0)
        
        //deviceManager.port?.close()
    }
}
