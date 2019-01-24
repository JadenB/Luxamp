//
//  VisualizerSettingsViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

fileprivate let DEFAULT_PRESET_INDEX = 1


// TODO: Split color and brightness side controls into seperate subviews run off the same viewcontroller
class VisualizerMainViewController: NSViewController, VisualizerDataDelegate, GradientEditorViewControllerDelegate, SaveDialogDelegate {
    
    var visualizer: Visualizer!
    var presetManager: VisualizerPresetManager!
    
    var brightnessSide: VisualizerSideViewController!
    var colorSide: VisualizerSideViewController!
    
    var hidden = true
    
    /* DYNAMICALLY SET ELEMENTS */
    @IBOutlet weak var brightnessSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var brightnessSmoothingLabelDownwards: NSTextField!
    @IBOutlet weak var colorSmoothingLabelUpwards: NSTextField!
    @IBOutlet weak var colorSmoothingLabelDownwards: NSTextField!
    
    /* USER SET ELEMENTS */
    @IBOutlet weak var presetMenu: NSPopUpButton!
    @IBOutlet weak var presetMenuDeleteItem: NSMenuItem!
    
    @IBOutlet weak var brightnessUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var brightnessDownwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var colorUpwardsSmoothingSlider: NSSlider!
    @IBOutlet weak var colorDownwardsSmoothingSlider: NSSlider!
    
    @IBOutlet weak var gradientView: GradientView!
    
    private var lastSelectedPresetName: String = "" // Needed for when 'Delete Preset' is clicked and the pulldown menu changes
    
    // MARK: - Core View Functions
    
    override func viewDidLoad() {
        super.viewDidLoad()
        visualizer.dataDelegate = self
        
        presetManager = VisualizerPresetManager()
        presetManager.apply(name: VisualizerPreset.defaultPreset.name)
        
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
    
    func populateMenus() {
        let presetNames = presetManager.getPresetNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after title and before save/delete
        }
        presetMenu.selectItem(at: 1)
    }
    
    func refreshView() {
        let v = visualizer!
        
        brightnessUpwardsSmoothingSlider.floatValue = v.brightness.upwardsSmoothing
        brightnessDownwardsSmoothingSlider.floatValue = v.brightness.downwardsSmoothing
        brightnessUpwardsSmoothingSliderChanged(brightnessUpwardsSmoothingSlider) // updates slider label
        brightnessDownwardsSmoothingSliderChanged(brightnessDownwardsSmoothingSlider) // updates slider label
        
        colorUpwardsSmoothingSlider.floatValue = v.color.upwardsSmoothing
        colorDownwardsSmoothingSlider.floatValue = v.color.downwardsSmoothing
        colorUpwardsSmoothingSliderChanged(colorUpwardsSmoothingSlider) // updates slider label
        colorDownwardsSmoothingSliderChanged(colorDownwardsSmoothingSlider) // updates slider label
        
        gradientView.gradient = v.gradient
    }
    
    func refreshAllViews() {
        brightnessSide.refreshView()
        colorSide.refreshView()
        refreshView()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "gradientPopoverSegue":
            let gradientEditor = segue.destinationController as! GradientEditorViewController
            gradientEditor.gradient = visualizer.gradient
            gradientEditor.delegate = self
        case "saveDialogSegue":
            let saveDialogController = segue.destinationController as! SaveDialogViewController
            saveDialogController.delegate = self
        case "brightnessSideViewSegue":
            brightnessSide = segue.destinationController as? VisualizerSideViewController
            brightnessSide.mapper = visualizer.brightness
            brightnessSide.name = "Brightness"
        case "colorSideViewSegue":
            colorSide = segue.destinationController as? VisualizerSideViewController
            colorSide.mapper = visualizer.color
            colorSide.name = "Color"
        default:
            print("error: unidentified segue \(segue.identifier ?? "no identifier")")
        }
    }
    
    // MARK: - Preset Menu
    
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
            performSegue(withIdentifier: "saveDialogSegue", sender: self)
        } else {
            presetManager.apply(name: sender.selectedItem?.title ?? PRESETMANAGER_DEFAULT_PRESET_NAME)
            presetMenu.title = "Preset: " + (presetMenu.selectedItem?.title ?? "Error")
            if sender.selectedItem?.title == PRESETMANAGER_DEFAULT_PRESET_NAME {
                presetMenuDeleteItem.isEnabled = false
            } else {
                presetMenuDeleteItem.isEnabled = true
                lastSelectedPresetName = sender.selectedItem!.title
            }
            
            refreshAllViews()
        }
    }
    
    func savePreset(withName name: String) {
        presetManager.saveCurrentSettings(name: name)
        presetMenu.insertItem(withTitle: name, at: presetMenu.numberOfItems - 3)
        presetMenu.selectItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func deletePreset(withName name: String) {
        presetMenu.selectItem(at: 1)
        presetManager.delete(name: name)
        presetMenu.removeItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    // MARK: - Center Controls
    
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
    
    // MARK: - VisualizerDataDelegate
    
    func didVisualizeWithData(brightnessData: VisualizerData, colorData: VisualizerData) {
        if hidden {
            return
        }
        
        brightnessSide.updateWithData(brightnessData)
        colorSide.updateWithData(colorData)
        gradientView.level = colorData.outputVal
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


