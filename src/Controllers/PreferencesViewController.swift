//
//  PreferencesViewController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let PREFERENCES_MAX_BRIGHTNESS_KEY = "maxBrightness"
let PREFERENCES_DELAY_KEY = "delay"

let DEVICEMENU_NONE_INDEX = 1


class PreferencesViewController: NSViewController {

    @IBOutlet weak var outputDeviceMenu: NSPopUpButton!
    @IBOutlet weak var delayField: NSTextField!
    @IBOutlet weak var delaySlider: NSSlider!
    @IBOutlet weak var maxBrightnessField: NSTextField!
    @IBOutlet weak var maxBrightnessSlider: NSSlider!
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delay: Int = UserDefaults.standard.integer(forKey: PREFERENCES_DELAY_KEY)
        delayField.integerValue = delay
        delaySlider.integerValue = delay
        
        let maxBrightness: Float = (UserDefaults.standard.object(forKey: PREFERENCES_MAX_BRIGHTNESS_KEY) as? Float) ?? 1.0
        maxBrightnessField.integerValue = Int(100 * maxBrightness)
        maxBrightnessSlider.integerValue = Int(100 * maxBrightness)
        
        outputDeviceMenu.addItem(withTitle: "None")
		outputDeviceMenu.addItems(withTitles:
			ORSSerialPortManager.shared().availablePorts.map { $0.path }
		)
        
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
    
    @IBAction func delayFieldChanged(_ sender: NSTextField) {
        delaySlider.integerValue = sender.integerValue
    }
    
    @IBAction func delaySliderChanged(_ sender: NSSlider) {
        delayField.integerValue = sender.integerValue
    }
    
    @IBAction func maxBrightnessFieldChanged(_ sender: NSTextField) {
        maxBrightnessSlider.integerValue = sender.integerValue
        let newMaxBrightness = Float(sender.integerValue) * 0.01
        UserDefaults.standard.set(newMaxBrightness, forKey: PREFERENCES_MAX_BRIGHTNESS_KEY)
        NotificationCenter.default.post(name: .didChangeMaxBrightness, object: nil, userInfo: [PREFERENCES_MAX_BRIGHTNESS_KEY : newMaxBrightness])
    }
    
    @IBAction func maxBrightnessSliderChanged(_ sender: NSSlider) {
        maxBrightnessField.integerValue = sender.integerValue
        let newMaxBrightness = Float(sender.integerValue) * 0.01
        UserDefaults.standard.set(newMaxBrightness, forKey: PREFERENCES_MAX_BRIGHTNESS_KEY)
        NotificationCenter.default.post(name: .didChangeMaxBrightness, object: nil, userInfo: [PREFERENCES_MAX_BRIGHTNESS_KEY : newMaxBrightness])
    }
    
    @IBAction func resetDefaultsPressed(_ sender: Any) {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
		
		os_log("UserDefaults reset by user", log: Log.user, type: .debug)
    }
    
    @objc func devicesAdded(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let addedNames = (userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]).map{ $0.path }
            for name in addedNames {
                outputDeviceMenu.insertItem(withTitle: name, at: 2)
            }
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
    static let didChangeMaxBrightness = Notification.Name("didChangeMaxBrightness")
}
