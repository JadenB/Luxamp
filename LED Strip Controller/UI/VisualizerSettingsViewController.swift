//
//  VisualizerSettingsViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class VisualizerSettingsViewController: NSViewController, VisualizerDataDelegate, GradientEditorViewControllerDelegate {
    
    var visualizer: Visualizer!
    var presetManager: VisualizerPresetManager!
    
    var hidden = true
    
    /* DYNAMICALLY SET ELEMENTS */
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
    
    /* USER SET ELEMENTS */
    @IBOutlet weak var presetMenu: NSPopUpButton!
    
    @IBOutlet weak var brightnessDriverMenu: NSPopUpButton!
    @IBOutlet weak var hueDriverMenu: NSPopUpButton!
    
    @IBOutlet weak var brightnessMaxField: VisualizerTextField!
    @IBOutlet weak var brightnessMinField: VisualizerTextField!
    @IBOutlet weak var brightnessInvertCheckbox: NSButton!
    @IBOutlet weak var brightnessAdaptiveCheckbox: NSButton!
    
    @IBOutlet weak var brightnessUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var brightnessDownwardsSmoothingSlider: NSSlider!
    
    @IBOutlet weak var hueMaxField: VisualizerTextField!
    @IBOutlet weak var hueMinField: VisualizerTextField!
    @IBOutlet weak var hueInvertCheckbox: NSButton!
    @IBOutlet weak var hueAdaptiveCheckbox: NSButton!
    
    @IBOutlet weak var hueUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var hueDownwardsSmoothingSlider: NSSlider!
    
    @IBOutlet weak var gradientView: GradientView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualizer.dataDelegate = self
        
        presetManager = VisualizerPresetManager(withVisualizer: visualizer)
        presetManager.applyPreset(name: VisualizerPreset.defaultPreset.name)
        
        populateMenus()
        refreshView()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        hidden = false
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        hidden = true
    }
    
    @IBAction func presetSelected(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            // delete preset
            print("delete")
        } else if sender.indexOfSelectedItem == sender.numberOfItems - 2 {
            // save preset
            print("save")
        } else {
            presetManager.applyPreset(name: sender.selectedItem?.title ?? "Default")
            sender.item(at: 0)?.title = "Preset: " + (sender.selectedItem?.title ?? "Error")
            refreshView()
        }
    }
    
    @IBAction func brightnessDriverSelected(_ sender: NSPopUpButton) {
        guard let driverName = sender.selectedItem?.title else {
            print("error: no item selected")
            return
        }
        visualizer.setBrightnessDriver(name: driverName)
    }
    
    @IBAction func hueDriverSelected(_ sender: NSPopUpButton) {
        guard let driverName = sender.selectedItem?.title else {
            print("error: no item selected")
            return
        }
        visualizer.setHueDriver(name: driverName)
    }
    
    @IBAction func brightnessMaxChanged(_ sender: NSTextField) {
        visualizer.brightness.max = sender.floatValue
    }
    
    @IBAction func brightnessMinChanged(_ sender: NSTextField) {
        visualizer.brightness.min = sender.floatValue
    }
    
    @IBAction func hueMaxChanged(_ sender: NSTextField) {
        visualizer.hue.max = sender.floatValue
    }
    
    @IBAction func hueMinChanged(_ sender: NSTextField) {
        visualizer.hue.min = sender.floatValue
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
    
    func populateMenus() {
        let presetNames = presetManager.getPresetNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after placeholder and before save/delete
        }
        
        brightnessDriverMenu.addItems(withTitles: visualizer.drivers.map{$0.name})
        hueDriverMenu.addItems(withTitles: visualizer.drivers.map{$0.name})
    }
    
    func refreshView() {
        let v = visualizer!
        brightnessDriverMenu.selectItem(withTitle: v.brightness.driver.name)
        hueDriverMenu.selectItem(withTitle: v.hue.driver.name)
        
        brightnessMaxField.floatValue = v.brightness.max
        brightnessMinField.floatValue = v.brightness.min
        brightnessInvertCheckbox.state = v.brightness.invert ? .on : .off
        brightnessAdaptiveCheckbox.state = v.brightness.useAdaptiveRange ? .on : .off
        
        brightnessUpwardsSmoothingSlider.floatValue = v.brightness.upwardsSmoothing
        brightnessDownwardsSmoothingSlider.floatValue = v.brightness.downwardsSmoothing
        brightnessUpwardsSmoothingSliderChanged(brightnessUpwardsSmoothingSlider) // updates slider labels
        brightnessDownwardsSmoothingSliderChanged(brightnessDownwardsSmoothingSlider)
        
        hueMaxField.floatValue = v.hue.max
        hueMinField.floatValue = v.hue.min
        hueInvertCheckbox.state = v.hue.invert ? .on : .off
        hueAdaptiveCheckbox.state = v.hue.useAdaptiveRange ? .on : .off
        
        hueUpwardsSmoothingSlider.floatValue = v.hue.upwardsSmoothing
        hueDownwardsSmoothingSlider.floatValue = v.hue.downwardsSmoothing
        hueUpwardsSmoothingSliderChanged(hueUpwardsSmoothingSlider)
        hueDownwardsSmoothingSliderChanged(hueDownwardsSmoothingSlider)
        
        gradientView.gradient = v.gradient
    }
    
    func didVisualizeWithData(brightness: Float, hue: Float, inputBrightness: Float, inputHue: Float) {
        if hidden {
            return
        }
        
        brightnessInputLevel.updateLevel(level: remapValueToBounds(inputBrightness, min: visualizer.brightness.min, max: visualizer.brightness.max))
        hueInputLevel.updateLevel(level: remapValueToBounds(inputHue, min: visualizer.hue.min, max: visualizer.hue.max))
        
        brightnessOutputLevel.updateLevel(level: brightness)
        hueOutputLevel.updateLevel(level: hue)
        
        brightnessOutputLabel.stringValue = String(format: "%.1f", brightness)
        brightnessInputLabel.stringValue = String(format: "%.1f", inputBrightness)
        hueOutputLabel.stringValue = String(format: "%.1f", hue)
        hueInputLabel.stringValue = String(format: "%.1f", inputHue)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let gradientEditor = (segue.destinationController as? NSWindowController)?.contentViewController as? GradientEditorViewController {
            gradientEditor.gradient = visualizer.gradient
            gradientEditor.delegate = self
        }
    }
    
    func didSetGradient(gradient: NSGradient) {
        visualizer.gradient = gradient
        gradientView.gradient = gradient
    }
    
}


