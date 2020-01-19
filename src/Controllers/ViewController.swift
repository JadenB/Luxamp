//
//  ViewController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa


class ViewController: NSViewController, AudioEngineDelegate, VisualizerDelegate,
                        ArcLevelViewDelegate, SaveDialogDelegate, GradientEditorDelegate {
    
    @IBOutlet weak var powerButton: NSButton!
    @IBOutlet weak var spectrum: SpectrumView!
    
    @IBOutlet weak var presetMenu: NSPopUpButton!
    @IBOutlet weak var presetMenuDeleteItem: NSMenuItem!
    @IBOutlet weak var arcLevelCenter: ArcLevelView!
    @IBOutlet weak var colorView: CircularColorWell!
    
    var brightnessSide: SideViewController!
    var colorSide: SideViewController!
    
    var audioEngine: AudioEngine!
    var musicVisualizer: Visualizer!
    var hidden = true
    var lastSelectedPresetName: String = ""
    
    var state: AppState = .Off {
        didSet {
            if state == .On {
                AppManager.disableSleep()
            } else {
                AppManager.enableSleep()
            }
        }
    }
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
        audioEngine = AudioEngine()
        audioEngine.delegate = self
        
        musicVisualizer = Visualizer()
        musicVisualizer.delegate = self
        
        arcLevelCenter.delegate = self
        
        populateMenus()
    }
	
	override func viewWillAppear() {
		refreshViews()
	}
    
    override func viewDidAppear() {
        super.viewDidAppear()
        hidden = false
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        hidden = true
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        switch segue.identifier! {
        case .brightnessSideSegue:
            brightnessSide = segue.destinationController as? SideViewController
			brightnessSide.mapper = musicVisualizer.brightness
			brightnessSide.headTitle = "Brightness Control"
        case .colorSideSegue:
            colorSide = segue.destinationController as? SideViewController
			colorSide.mapper = musicVisualizer.color
			colorSide.headTitle = "Color Control"
        case .gradientEditorSegue:
            guard let gradientWindow = segue.destinationController as? NSWindowController else {
                NSLog("Failed to cast gradient window controller")
                return
            }
            
            let gradientEditor = gradientWindow.contentViewController as! GradientEditorViewController
            gradientEditor.gradient = musicVisualizer.gradient
            gradientEditor.delegate = self
        case .saveDialogSegue:
            let saveDialogController = segue.destinationController as! SaveDialogViewController
            saveDialogController.delegate = self
        default:
            print("error: unidentified segue \(segue.identifier ?? "no identifier")")
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func powerButtonPressed(_ sender: NSButton) {
        state = (sender.state == .on) ? .On : .Off
        
        if state == .On {
            LightController.shared.turnOn()
            startAudioVisualization()
            colorView.isEnabled = false
        } else {
            LightController.shared.turnOff()
            stopAudioVisualization()
            spectrum.clear()
			colorView.color = .black
			arcLevelCenter.setBrightnessLevel(to: 0.0)
			arcLevelCenter.setColorLevel(to: 0.0)
        }
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
            performSegue(withIdentifier: "saveDialogSegue", sender: self)
        } else {
            musicVisualizer.presets.apply(name: sender.selectedItem?.title ?? PRESETMANAGER_DEFAULT_PRESET_NAME)
            presetMenu.title = "Preset: " + (presetMenu.selectedItem?.title ?? "Error")
            if sender.selectedItem?.title == PRESETMANAGER_DEFAULT_PRESET_NAME {
                presetMenuDeleteItem.isEnabled = false
            } else {
                presetMenuDeleteItem.isEnabled = true
                lastSelectedPresetName = sender.selectedItem!.title
            }
            
            refreshViews()
        }
    }
    
    func savePreset(withName name: String) {
        musicVisualizer.presets.saveCurrentSettings(name: name)
		print(musicVisualizer.brightness.outputMin)
        presetMenu.insertItem(withTitle: name, at: presetMenu.numberOfItems - 3)
        presetMenu.selectItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func deletePreset(withName name: String) {
        presetMenu.selectItem(at: 1)
        musicVisualizer.presets.delete(name: name)
        presetMenu.removeItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func startAudioVisualization() {
        audioEngine.startTappingInput()
    }
    
    func stopAudioVisualization() {
        audioEngine.stopTappingInput()
		brightnessSide.clearViews()
		colorSide.clearViews()
    }
    
    func refreshViews() {
        arcLevelCenter.colorGradient = musicVisualizer.gradient
		brightnessSide.refreshViews()
		colorSide.refreshViews()
    }
    
    func populateMenus() {
        let presetNames = musicVisualizer.presets.getNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after title and before save/delete
        }
        presetMenu.selectItem(at: 1)
    }
    
    // MARK: - AudioEngineDelegate
    
    func didTapInput(withBuffer buffer: AnalyzedBuffer) {
        if state == .On {
            musicVisualizer.visualizeBuffer(buffer)
            spectrum.setSpectrum(buffer.visualSpectrum())
        }
    }
    
    // MARK: - VisualizerDelegate
    
    func didVisualizeIntoColor(_ color: NSColor, brightnessVal: Float, colorVal: Float) {
        LightController.shared.setColor(color: color)
        colorView.color = color
        
        arcLevelCenter.setBrightnessLevel(to: brightnessVal)
        arcLevelCenter.setColorLevel(to: colorVal)
    }
    
    func didVisualizeWithData(brightnessData: VisualizerData, colorData: VisualizerData) {
        brightnessSide.updateWithData(brightnessData)
        colorSide.updateWithData(colorData)
    }
    
    // MARK: - ArcLevelViewDelegate
    
    func arcLevelColorResetClicked() {
        musicVisualizer.gradient = musicVisualizer.presets.defaultP.gradient
        arcLevelCenter.colorGradient = musicVisualizer.gradient
    }
    
    func arcLevelColorClicked(with event: NSEvent) {
        performSegue(withIdentifier: .gradientEditorSegue, sender: nil)
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
        } else if musicVisualizer.presets.getNames().contains(name) {
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
    
    // MARK: - GradientEditorDelegate
    
    func gradientEditorSetGradient(_ gradient: NSGradient) {
        musicVisualizer.gradient = gradient
        arcLevelCenter.colorGradient = gradient
    }
    
}

enum AppState {
    case On
    case Off
}

extension NSStoryboardSegue.Identifier {
    static let saveDialogSegue = NSStoryboardSegue.Identifier("saveDialogSegue")
    static let gradientEditorSegue = NSStoryboardSegue.Identifier("gradientEditorSegue")
    static let brightnessSideSegue = NSStoryboardSegue.Identifier("brightnessSideSegue")
    static let colorSideSegue = NSStoryboardSegue.Identifier("colorSideSegue")
}

