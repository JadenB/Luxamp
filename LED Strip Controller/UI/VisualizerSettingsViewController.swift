//
//  VisualizerSettingsViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let DEFAULT_PRESET_INDEX = 1

class VisualizerSettingsViewController: NSViewController, VisualizerDataDelegate, GradientEditorViewControllerDelegate, SaveDialogDelegate {
    
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
    @IBOutlet weak var presetMenuDeleteItem: NSMenuItem!
    
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
    
    private var lastSelectedPresetName: String = "" // Needed for when 'Delete Preset' is clicked and the pulldown menu changes
    
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
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Are you sure you want to delete \"\(lastSelectedPresetName)\"?"
            alert.informativeText = "You are about to permanently delete this preset. Once deleted it cannot be recovered."
            alert.beginSheetModal(for: view.window!) { response in
                if response == .alertFirstButtonReturn {
                    self.deletePreset(withName: self.lastSelectedPresetName)
                }
            }
            
        } else if sender.indexOfSelectedItem == sender.numberOfItems - 2 {
            performSegue(withIdentifier: "SaveDialogSegue", sender: self)
        } else {
            presetManager.applyPreset(name: sender.selectedItem?.title ?? PRESETMANAGER_DEFAULT_PRESET_NAME)
            presetMenu.title = "Preset: " + (presetMenu.selectedItem?.title ?? "Error")
            if sender.selectedItem?.title == PRESETMANAGER_DEFAULT_PRESET_NAME {
                presetMenuDeleteItem.isEnabled = false
            } else {
                presetMenuDeleteItem.isEnabled = true
                lastSelectedPresetName = sender.selectedItem!.title
            }
            
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
        visualizer.brightness.invert = sender.state == .on
    }
    
    @IBAction func colorInvertPressed(_ sender: NSButton) {
        visualizer.color.invert = sender.state == .on
    }
    
    @IBAction func brightnessAdaptivePressed(_ sender: NSButton) {
        visualizer.brightness.useAdaptiveRange = sender.state == .on
        brightnessInputLevel.showSubrange = visualizer.brightness.useAdaptiveRange
    }
    
    @IBAction func colorAdaptivePressed(_ sender: NSButton) {
        visualizer.color.useAdaptiveRange = sender.state == .on
        colorInputLevel.showSubrange = visualizer.color.useAdaptiveRange
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
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after title and before save/delete
        }
        
        presetMenu.selectItem(at: 1)
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
    
    func savePreset(withName name: String) {
        presetManager.saveCurrentStateAsPreset(name: name)
        presetMenu.insertItem(withTitle: name, at: presetMenu.numberOfItems - 3)
        presetMenu.selectItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func deletePreset(withName name: String) {
        presetMenu.selectItem(at: 1)
        presetManager.deletePreset(name: name)
        presetMenu.removeItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "SaveDialogSegue" {
            let saveDialogController = segue.destinationController as! SaveDialogViewController
            saveDialogController.delegate = self
        } else if segue.identifier == "GradientEditorSegue" {
            let gradientEditor = (segue.destinationController as! NSWindowController).contentViewController as! GradientEditorViewController
            gradientEditor.gradient = visualizer.gradient
            gradientEditor.delegate = self
        }
    }
    
    // MARK: - VisualizerDataDelegate
    
    func didVisualizeWithData(_ data: VisualizerData) {
        if hidden {
            return
        }
        
        brightnessInputLevel.level = remapValueToBounds(data.inputBrightness, min: visualizer.brightness.min, max: visualizer.brightness.max)
        brightnessInputLevel.subrangeMax = data.adaptiveBrightnessRange.max
        brightnessInputLevel.subrangeMin = data.adaptiveBrightnessRange.min
        colorInputLevel.level = remapValueToBounds(data.inputColor, min: visualizer.color.min, max: visualizer.color.max)
        colorInputLevel.subrangeMax = data.adaptiveColorRange.max
        colorInputLevel.subrangeMin = data.adaptiveColorRange.min
        
        brightnessOutputLevel.level = data.outputBrightness
        colorOutputLevel.level = data.outputColor
        gradientView.level = data.outputColor
        
        brightnessOutputLabel.stringValue = String(format: "%.1f", data.outputBrightness)
        brightnessInputLabel.stringValue = String(format: "%.1f", data.inputBrightness)
        colorOutputLabel.stringValue = String(format: "%.1f", data.outputColor)
        colorInputLabel.stringValue = String(format: "%.1f", data.inputColor)
    }
    
    // MARK: - GradientEditorViewControllerDelegate
    
    func didSetGradient(gradient: NSGradient) {
        visualizer.gradient = gradient
        gradientView.gradient = gradient
    }
    
    // MARK: - SaveDialogDelegate
    
    func saveDialogSaved(withName name: String, _ sender: SaveDialogViewController) {
        if name == PRESETMANAGER_DEFAULT_PRESET_NAME || name == "Delete Preset" || name == "Save Preset..." {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.messageText = "Invalid Preset Name"
            alert.informativeText = "Please choose a different name"
            alert.beginSheetModal(for: view.window!, completionHandler: nil)
        } else if presetManager.getPresetNames().contains(name) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "\"\(name)\" already exists. Do you want to replace it?"
            alert.informativeText = "A preset with the same name already exists. Replacing it will overwrite its current settings."
            alert.beginSheetModal(for: view.window!) { response in
                if response == .alertFirstButtonReturn {
                    self.savePreset(withName: name)
                    sender.dismiss(nil)
                }
            }
        } else {
            savePreset(withName: name)
            sender.dismiss(nil)
        }
    } // end saveDialogSaved()
    
    func saveDialogCanceled(_ sender: SaveDialogViewController) {
        sender.dismiss(nil)
    }
}


