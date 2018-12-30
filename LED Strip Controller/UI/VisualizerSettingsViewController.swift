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
    @IBOutlet weak var colorInputLevel: LevelView!
    @IBOutlet weak var colorOutputLevel: LevelView!
    
    @IBOutlet weak var brightnessInputLabel: NSTextField!
    @IBOutlet weak var brightnessOutputLabel: NSTextField!
    @IBOutlet weak var colorInputLabel: NSTextField!
    @IBOutlet weak var colorOutputLabel: NSTextField!
    
    @IBOutlet weak var brightnessSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var brightnessSmoothingLabelDownwards: NSTextField!
    @IBOutlet weak var colorSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var colorSmoothingLabelDownwards: NSTextField!
    
    /* USER SET ELEMENTS */
    @IBOutlet weak var presetMenu: NSPopUpButton!
    
    @IBOutlet weak var brightnessDriverMenu: NSPopUpButton!
    @IBOutlet weak var colorDriverMenu: NSPopUpButton!
    
    @IBOutlet weak var brightnessMaxField: VisualizerTextField!
    @IBOutlet weak var brightnessMinField: VisualizerTextField!
    @IBOutlet weak var brightnessInvertCheckbox: NSButton!
    @IBOutlet weak var brightnessAdaptiveCheckbox: NSButton!
    
    @IBOutlet weak var brightnessUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var brightnessDownwardsSmoothingSlider: NSSlider!
    
    @IBOutlet weak var colorMaxField: VisualizerTextField!
    @IBOutlet weak var colorMinField: VisualizerTextField!
    @IBOutlet weak var colorInvertCheckbox: NSButton!
    @IBOutlet weak var colorAdaptiveCheckbox: NSButton!
    
    @IBOutlet weak var colorUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var colorDownwardsSmoothingSlider: NSSlider!
    
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
        visualizer.brightness.setDriver(withName: driverName)
    }
    
    @IBAction func colorDriverSelected(_ sender: NSPopUpButton) {
        guard let driverName = sender.selectedItem?.title else {
            print("error: no item selected")
            return
        }
        visualizer.color.setDriver(withName: driverName)
    }
    
    @IBAction func brightnessMaxChanged(_ sender: NSTextField) {
        visualizer.brightness.max = sender.floatValue
    }
    
    @IBAction func brightnessMinChanged(_ sender: NSTextField) {
        visualizer.brightness.min = sender.floatValue
    }
    
    @IBAction func colorMaxChanged(_ sender: NSTextField) {
        visualizer.color.max = sender.floatValue
    }
    
    @IBAction func colorMinChanged(_ sender: NSTextField) {
        visualizer.color.min = sender.floatValue
    }
    
    @IBAction func brightnessInvertPressed(_ sender: NSButton) {
        visualizer.brightness.invert = sender.state.rawValue == 1
    }
    
    @IBAction func colorInvertPressed(_ sender: NSButton) {
        visualizer.color.invert = sender.state.rawValue == 1
    }
    
    @IBAction func brightnessUpwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.brightness.upwardsSmoothing = sender.floatValue
        brightnessSmoothingLabelUpwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func brightnessDownwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.brightness.downwardsSmoothing = sender.floatValue
        brightnessSmoothingLabelDownwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func colorUpwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.color.upwardsSmoothing = sender.floatValue
        colorSmoothingLabelUpwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func colorDownwardsSmoothingSliderChanged(_ sender: NSSlider) {
        visualizer.color.downwardsSmoothing = sender.floatValue
        colorSmoothingLabelDownwards.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func resetGradientButtonPressed(_ sender: Any) {
        visualizer.gradient = VisualizerPreset.defaultPreset.gradient
        gradientView.gradient = visualizer.gradient
    }
    
    override func setNilValueForKey(_ key: String) {
        return
    }
    
    func populateMenus() {
        let presetNames = presetManager.getPresetNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after placeholder and before save/delete
        }
        
        brightnessDriverMenu.addItems(withTitles: visualizer.brightness.drivers())
        colorDriverMenu.addItems(withTitles: visualizer.color.drivers())
    }
    
    func refreshView() {
        let v = visualizer!
        brightnessDriverMenu.selectItem(withTitle: v.brightness.driverName())
        colorDriverMenu.selectItem(withTitle: v.color.driverName())
        
        brightnessMaxField.floatValue = v.brightness.max
        brightnessMinField.floatValue = v.brightness.min
        brightnessInvertCheckbox.state = v.brightness.invert ? .on : .off
        brightnessAdaptiveCheckbox.state = v.brightness.useAdaptiveRange ? .on : .off
        
        brightnessUpwardsSmoothingSlider.floatValue = v.brightness.upwardsSmoothing
        brightnessDownwardsSmoothingSlider.floatValue = v.brightness.downwardsSmoothing
        brightnessUpwardsSmoothingSliderChanged(brightnessUpwardsSmoothingSlider) // updates slider labels
        brightnessDownwardsSmoothingSliderChanged(brightnessDownwardsSmoothingSlider)
        
        colorMaxField.floatValue = v.color.max
        colorMinField.floatValue = v.color.min
        colorInvertCheckbox.state = v.color.invert ? .on : .off
        colorAdaptiveCheckbox.state = v.color.useAdaptiveRange ? .on : .off
        
        colorUpwardsSmoothingSlider.floatValue = v.color.upwardsSmoothing
        colorDownwardsSmoothingSlider.floatValue = v.color.downwardsSmoothing
        colorUpwardsSmoothingSliderChanged(colorUpwardsSmoothingSlider)
        colorDownwardsSmoothingSliderChanged(colorDownwardsSmoothingSlider)
        
        gradientView.gradient = v.gradient
    }
    
    func didVisualizeWithData(brightness: Float, color: Float, inputBrightness: Float, inputColor: Float) {
        if hidden {
            return
        }
        
        brightnessInputLevel.level = remapValueToBounds(inputBrightness, min: visualizer.brightness.min, max: visualizer.brightness.max)
        colorInputLevel.level = remapValueToBounds(inputColor, min: visualizer.color.min, max: visualizer.color.max)
        
        brightnessOutputLevel.level = brightness
        colorOutputLevel.level = color
        
        brightnessOutputLabel.stringValue = String(format: "%.1f", brightness)
        brightnessInputLabel.stringValue = String(format: "%.1f", inputBrightness)
        colorOutputLabel.stringValue = String(format: "%.1f", color)
        colorInputLabel.stringValue = String(format: "%.1f", inputColor)
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


