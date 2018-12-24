//
//  VisualizerSettingsViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class VisualizerSettingsViewController: NSViewController {
    
    var visualizer: Visualizer!
    
    @IBOutlet weak var brightnessDriverOptions: NSPopUpButton!
    @IBOutlet weak var hueDriverOptions: NSPopUpButton!
    
    @IBOutlet weak var testLevels: LevelView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateMenus()
        testLevels.backgroundColor = .black
        testLevels.color = .purple
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
    
    // TODO: func loadPreset
    
    func populateMenus() {
        brightnessDriverOptions.addItems(withTitles: visualizer.drivers.map{$0.name})
        hueDriverOptions.addItems(withTitles: visualizer.drivers.map{$0.name})
    }
    
    func selectCustomDriver(id: Int) -> VisualizationDriver {
        return ConstantValueDriver(constant: 0.5)
    }
    
}

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
        return engine.bProcessor.averageMagOfRange(startIndex...endIndex, withFalloff: falloff)
    }
    
}
