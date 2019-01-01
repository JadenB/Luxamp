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
    @IBOutlet weak var delayField: NSTextField!
    @IBOutlet weak var delaySlider: NSSlider!
    @IBOutlet weak var maxBrightnessField: NSTextField!
    @IBOutlet weak var maxBrightnessSlider: NSSlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let delay: Int = UserDefaults.standard.integer(forKey: USERDEFAULTS_DELAY_KEY)
        delayField.integerValue = delay
        delaySlider.integerValue = delay
        
        let maxBrightness: Float = (UserDefaults.standard.object(forKey: USERDEFAULTS_MAX_BRIGHTNESS_KEY) as? Float) ?? 1.0
        maxBrightnessField.integerValue = Int(100 * maxBrightness)
        maxBrightnessSlider.integerValue = Int(100 * maxBrightness)
    }
    
    override func viewWillAppear() {
        let deviceManager = DeviceManager.shared
        outputDeviceList.addItems(withTitles: deviceManager.getDevices())
        
        if deviceManager.deviceIsSelected() {
            outputDeviceList.selectItem(withTitle: deviceManager.selectedDevice())
        }
        
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(devicesAdded), name: .ORSSerialPortsWereConnected, object: nil)
        nc.addObserver(self, selector: #selector(devicesRemoved), name: .ORSSerialPortsWereDisconnected, object: nil)
    }
    
    override func viewDidDisappear() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func outputDeviceSelected(_ sender: NSPopUpButton) {
        guard let devicePath = sender.selectedItem?.title else {
            print("Error: nothing selected")
            return
        }
        
        if !DeviceManager.shared.selectDevice(withPath: devicePath) {
            outputDeviceList.selectItem(at: 0)
            return
        }
        
        DeviceManager.shared.activateDevice()
    }
    
    @IBAction func delayFieldChanged(_ sender: NSTextField) {
        delaySlider.integerValue = sender.integerValue
        LightController.shared.delay = sender.integerValue
    }
    
    @IBAction func delaySliderChanged(_ sender: NSSlider) {
        delayField.integerValue = sender.integerValue
        LightController.shared.delay = sender.integerValue
    }
    
    @IBAction func maxBrightnessFieldChanged(_ sender: NSTextField) {
        maxBrightnessSlider.integerValue = sender.integerValue
        LightController.shared.delay = sender.integerValue
        NotificationCenter.default.post(name: .didChangeMaxBrightness, object: nil, userInfo: ["maxBrightness":Float(sender.integerValue) * 0.01])
    }
    
    @IBAction func maxBrightnessSliderChanged(_ sender: NSSlider) {
        maxBrightnessField.integerValue = sender.integerValue
        LightController.shared.delay = sender.integerValue
        NotificationCenter.default.post(name: .didChangeMaxBrightness, object: nil, userInfo: ["maxBrightness":Float(sender.integerValue) * 0.01])
    }
    
    @IBAction func resetDefaultsPressed(_ sender: Any) {
        let defaults = UserDefaults.standard
        let dictionary = defaults.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            defaults.removeObject(forKey: key)
        }
    }
    
    @objc func devicesAdded(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let addedNames = (userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]).map{ $0.path }
            for name in addedNames {
                outputDeviceList.insertItem(withTitle: name, at: 1)
            }
        }
    }
    
    @objc func devicesRemoved(_ notification: Notification) {
        if let userInfo = notification.userInfo {
            let removedNames = (userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]).map{ $0.path }
            for name in removedNames {
                if name == DeviceManager.shared.selectedDevice() {
                    outputDeviceList.selectItem(at: 0)
                }
                outputDeviceList.removeItem(withTitle: name)
            }
        }
    }
}

extension Notification.Name {
    static let didChangeMaxBrightness = Notification.Name("didChangeMaxBrightness")
}
