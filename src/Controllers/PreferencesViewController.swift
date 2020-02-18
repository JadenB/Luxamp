//
//  PreferencesViewController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let PREFERENCES_SELECTED_DEVICE_KEY = "selectedDevice"
let PREFERENCES_DELAY_KEY = "delay"

let DEVICEMENU_NONE_INDEX = 1

class PreferencesViewController: NSViewController {

    @IBOutlet weak var outputDeviceMenu: NSPopUpButton!
//    @IBOutlet weak var delayField: NSTextField!
//    @IBOutlet weak var delaySlider: NSSlider!
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let delay: Int = UserDefaults.standard.integer(forKey: PREFERENCES_DELAY_KEY)
//        delayField.integerValue = delay
//        delaySlider.integerValue = delay
        
        outputDeviceMenu.addItem(withTitle: "None")
		outputDeviceMenu.addItems(withTitles:
			ORSSerialPortManager.shared().availablePorts.map { $0.path }
		)
		
		let selectedDevice = UserDefaults.standard.object(forKey: PREFERENCES_SELECTED_DEVICE_KEY) as? String
		
		if selectedDevice != nil && outputDeviceMenu.indexOfItem(withTitle: selectedDevice!) != -1 {
			outputDeviceMenu.selectItem(withTitle: selectedDevice!)
		} else {
			outputDeviceMenu.selectItem(at: DEVICEMENU_NONE_INDEX)
		}
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(devicesAdded), name: .ORSSerialPortsWereConnected, object: nil)
        nc.addObserver(self, selector: #selector(devicesRemoved), name: .ORSSerialPortsWereDisconnected, object: nil)
    }
    
    @IBAction func outputDeviceSelected(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == DEVICEMENU_NONE_INDEX {
            // 'None' selected
			FixtureManager.sharedFixture.disconnectFromController()
            return
        }
        
        guard let devicePath = sender.selectedItem?.title else {
            print("Error: nothing selected")
            return
        }
        
		os_log("User selected device %s", log: Log.user, type: .debug, devicePath)
		FixtureManager.sharedFixture.connectToController(devicePath: devicePath)
    }
    
//    @IBAction func delayFieldChanged(_ sender: NSTextField) {
//        delaySlider.integerValue = sender.integerValue
//		UserDefaults.standard.set(sender.integerValue, forKey: PREFERENCES_DELAY_KEY)
//		NotificationCenter.default.post(name: .didChangeDelay, object: nil, userInfo: [PREFERENCES_DELAY_KEY : sender.integerValue])
//    }
//
//    @IBAction func delaySliderChanged(_ sender: NSSlider) {
//        delayField.integerValue = sender.integerValue
//		UserDefaults.standard.set(sender.integerValue, forKey: PREFERENCES_DELAY_KEY)
//		NotificationCenter.default.post(name: .didChangeDelay, object: nil, userInfo: [PREFERENCES_DELAY_KEY : sender.integerValue])
//    }
    
    @IBAction func resetDefaultsPressed(_ sender: Any) {
        let domain = Bundle.main.bundleIdentifier!
		UserDefaults.standard.removePersistentDomain(forName: domain)
		UserDefaults.standard.synchronize()
		
		os_log("UserDefaults reset by user", log: Log.user, type: .debug)
    }
    
    @objc func devicesAdded(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let addedPaths = (userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]).map{ $0.path }
            for path in addedPaths {
                outputDeviceMenu.insertItem(withTitle: path, at: 2)
            }
        }
		
		let selectedDevice = UserDefaults.standard.object(forKey: PREFERENCES_SELECTED_DEVICE_KEY) as? String
		
		if selectedDevice != nil && outputDeviceMenu.indexOfItem(withTitle: selectedDevice!) != -1 {
			outputDeviceMenu.selectItem(withTitle: selectedDevice!)
		} else {
			outputDeviceMenu.selectItem(at: DEVICEMENU_NONE_INDEX)
		}
    }
    
    @objc func devicesRemoved(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let removedNames = (userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]).map{ $0.path }
            for name in removedNames {
				if name == outputDeviceMenu.titleOfSelectedItem {
                    outputDeviceMenu.selectItem(at: 0)
					FixtureManager.sharedFixture.disconnectFromController()
                }
                outputDeviceMenu.removeItem(withTitle: name)
            }
        }
    }
}

extension Notification.Name {
	static let didChangeDelay = Notification.Name("didChangeDelay")
}
