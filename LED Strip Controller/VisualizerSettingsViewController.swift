//
//  VisualizerSettingsViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class VisualizerSettingsViewController: NSViewController, VisualizerDataDelegate {
    
    var visualizer: Visualizer!
    
    var hidden = true
    
    @IBOutlet weak var brightnessDriverOptions: NSPopUpButton!
    @IBOutlet weak var hueDriverOptions: NSPopUpButton!
    
    @IBOutlet weak var brightnessInputLevel: LevelView!
    @IBOutlet weak var brightnessOutputLevel: LevelView!
    @IBOutlet weak var hueInputLevel: LevelView!
    @IBOutlet weak var hueOutputLevel: LevelView!
    
    @IBOutlet weak var brightnessInputLabel: NSTextField!
    @IBOutlet weak var brightnessOutputLabel: NSTextField!
    @IBOutlet weak var hueInputLabel: NSTextField!
    @IBOutlet weak var hueOutputLabel: NSTextField!
    
    @IBOutlet weak var brightnessSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var brightnessSmoothingLabelDownwards: NSTextField!
    @IBOutlet weak var hueSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var hueSmoothingLabelDownwards: NSTextField!
    
    @objc dynamic var brightnessInputMax: Float = 1.0
    @objc dynamic var brightnessInputMin: Float = 0.0
    var brightnessSliderMax: Float = 1.0
    var brightnessSliderMin: Float = 0.0
    
    @objc dynamic var hueInputMax: Float = 1.0
    @objc dynamic var hueInputMin: Float = 0.0
    var hueSliderMax: Float = 1.0
    var hueSliderMin: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateMenus()
        visualizer.dataDelegate = self
        
        brightnessDriverSelected(brightnessDriverOptions)
        hueDriverSelected(hueDriverOptions)
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        hidden = false
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        hidden = true
    }
    
    @IBAction func brightnessDriverSelected(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        
        if index < PREBUILT_DRIVERS {
            visualizer.setBrightnessDriver(id: index)
        } else {
            visualizer.setCustomBrightnessDriver(driver: selectCustomDriver(id: index))
        }
    }
    
    @IBAction func hueDriverSelected(_ sender: NSPopUpButton) {
        let index = sender.indexOfSelectedItem
        
        if index < PREBUILT_DRIVERS {
            visualizer.setHueDriver(id: index)
        } else {
            visualizer.setCustomHueDriver(driver: selectCustomDriver(id: index))
        }
    }
    
    @IBAction func brightnessMaxChanged(_ sender: Any) {
        visualizer.brightness.max = brightnessInputMin + (brightnessInputMax - brightnessInputMin) * brightnessSliderMax
    }
    
    @IBAction func brightnessMinChanged(_ sender: Any) {
        visualizer.brightness.min = brightnessInputMin + (brightnessInputMax - brightnessInputMin) * brightnessSliderMin
    }
    
    @IBAction func hueMaxChanged(_ sender: Any) {
        visualizer.hue.max = hueInputMin + (hueInputMax - hueInputMin) * hueSliderMax
    }
    
    @IBAction func hueMinChanged(_ sender: Any) {
        visualizer.hue.min = hueInputMin + (hueInputMax - hueInputMin) * hueSliderMin
    }
    
    @IBAction func brightnessInvertPressed(_ sender: NSButton) {
        visualizer.brightness.invert = sender.state.rawValue == 1
    }
    
    @IBAction func hueInvertPressed(_ sender: NSButton) {
        visualizer.hue.invert = sender.state.rawValue == 1
    }
    
    @IBAction func brightnessUpwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.brightness.upwardsSmoothing = sender.floatValue
        brightnessSmoothingLabelUpwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func brightnessDownwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.brightness.downwardsSmoothing = sender.floatValue
        brightnessSmoothingLabelDownwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func hueUpwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.hue.upwardsSmoothing = sender.floatValue
        hueSmoothingLabelUpwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func hueDownwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.hue.downwardsSmoothing = sender.floatValue
        hueSmoothingLabelDownwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    override func setNilValueForKey(_ key: String) {
        return
    }
    
    // TODO: func loadPreset
    
    func populateMenus() {
        brightnessDriverOptions.addItems(withTitles: visualizer.drivers.map{$0.name})
        hueDriverOptions.addItems(withTitles: visualizer.drivers.map{$0.name})
        
        addCustomDriverToMenu(driver: PartialMagnitudeSpectrumDriver(first: 0, last: 0, falloff: 0))
    }
    
    func addCustomDriverToMenu(driver: VisualizationDriver) {
        brightnessDriverOptions.addItem(withTitle: driver.name)
        hueDriverOptions.addItem(withTitle: driver.name)
    }
    
    func selectCustomDriver(id: Int) -> VisualizationDriver {
        return PartialMagnitudeSpectrumDriver(first: 0, last: 3, falloff: 2)
    }
    
    func didVisualizeWithData(brightness: Float, hue: Float, rawBrightness: Float, rawHue: Float) {
        if hidden {
            return
        }
        
        brightnessInputLevel.updateLevel(level: remapValueToBounds(rawBrightness, min: brightnessInputMin, max: brightnessInputMax))
        hueInputLevel.updateLevel(level: remapValueToBounds(rawHue, min: hueInputMin, max: hueInputMax))
        brightnessOutputLevel.updateLevel(level: brightness)
        hueOutputLevel.updateLevel(level: hue)
        
        brightnessOutputLabel.stringValue = String(format: "%.1f", brightness)
        brightnessInputLabel.stringValue = String(format: "%.1f", rawBrightness)
        hueOutputLabel.stringValue = String(format: "%.1f", hue)
        hueInputLabel.stringValue = String(format: "%.1f", rawHue)
    }
    
}

/* CUSTOM DRIVERS */

class ConstantValueDriver: VisualizationDriver {
    
    let constant: Float
    
    var name: String {
        get {
            return "Constant Value"
        }
    }
    
    init(constant: Float) {
        if constant > 1.0 {
            self.constant = 1.0
        } else if constant < 0.0 {
            self.constant = 0.0
        } else {
            self.constant = constant
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return constant
    }
}

class PartialMagnitudeSpectrumDriver: VisualizationDriver {
    
    var name: String {
        get {
            return "Magnitude Spectrum"
        }
    }
    
    let falloff: Int
    let startIndex: Int
    let endIndex: Int
    
    init(first: Int, last: Int, falloff: Int) {
        startIndex = first
        endIndex = last
        self.falloff = falloff
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(startIndex...endIndex, withFalloff: falloff) / 100
    }
    
}
