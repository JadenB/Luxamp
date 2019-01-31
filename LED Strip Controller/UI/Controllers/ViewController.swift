//
//  ViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa
import GistSwift

class ViewController: NSViewController, AudioEngineDelegate, VisualizerOutputDelegate, LightPatternManagerDelegate, ArcLevelViewDelegate {
    
    @IBOutlet weak var powerButton: NSButton!
    @IBOutlet weak var spectrum: SpectrumView!
    
    @IBOutlet weak var presetMenu: NSPopUpButton!
    @IBOutlet weak var presetMenuDeleteItem: NSMenuItem!
    @IBOutlet weak var centerCircleView: ArcLevelView!
    @IBOutlet weak var colorView: CircularColorWell!
    
    var audioEngine: AudioEngine!
    var musicVisualizer: Visualizer!
    var patternManager = LightPatternManager()
    var hidden = true
    var lastSelectedPresetName: String = ""
    
    var state: AppState = .Off {
        didSet {
            if state == .On {
                AppManager.disableSleep()
            } else {
                AppManager.enableSleep()
            }
            patternManager.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(refreshRate: Double(SAMPLE_RATE) / Double(BUFFER_SIZE))
        audioEngine.delegate = self
        musicVisualizer = Visualizer(withEngine: audioEngine)
        musicVisualizer.outputDelegate = self
        patternManager.delegate = self
        
        populateMenus()
        refreshAllViews()
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
        
    }
    
    @IBAction func colorWellChanged(_ sender: NSColorWell) {
        LightController.shared.setColorIgnoreDelay(color: sender.color)
    }
    
    @IBAction func powerButtonPressed(_ sender: NSButton) {
        state = (sender.state == .on) ? .On : .Off
        
        if state == .On {
            LightController.shared.turnOn()
            LightController.shared.setColorIgnoreDelay(color: colorView.color)
            startAudioVisualization()
            
            colorView.isEnabled = false
        } else {
            LightController.shared.turnOff()
            stopAudioVisualization()
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
            
            refreshAllViews()
        }
    }
    
    func savePreset(withName name: String) {
        musicVisualizer.presets.saveCurrentSettings(name: name)
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
        audioEngine.start()
    }
    
    func stopAudioVisualization() {
        audioEngine.stop()
    }
    
    func refreshAllViews() {
        centerCircleView.colorGradient = musicVisualizer.gradient
    }
    
    func populateMenus() {
        let presetNames = musicVisualizer.presets.getNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after title and before save/delete
        }
        presetMenu.selectItem(at: 1)
    }
    
    // MARK: - AudioEngineDelegate
    
    func didRefreshAudioEngine() {
        if state == .On {
            musicVisualizer.visualize()
        }
    }
    
    func didRefreshVisualSpectrum(_ s: [Float]) {
        if !hidden {
            spectrum.setSpectrum(s)
        }
    }
    
    func audioDeviceChanged() {
        LightController.shared.setColor(color: .black)
        let alert = NSAlert()
        alert.messageText = "Audio Device Changed"
        alert.informativeText = "The app must be restarted to continue analyzing audio."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Restart")
        alert.addButton(withTitle: "Quit")
        alert.beginSheetModal(for: view.window!) { response in
            if response == .alertFirstButtonReturn {
                AppManager.restartApp()
            } else {
                AppManager.quitApp()
            }
        }
    }
    
    // MARK: - VisualizerOutputDelegate
    
    func didVisualizeIntoColor(_ color: NSColor, brightnessVal: Float, colorVal: Float) {
        
        LightController.shared.setColor(color: color)
        colorView.color = color
        
        centerCircleView.setBrightnessLevel(to: brightnessVal)
        centerCircleView.setColorLevel(to: colorVal)
    }
    
    // MARK: - LightPatternManagerDelegate
    
    func didGenerateColorFromPattern(_ color: NSColor) {
        LightController.shared.setColorIgnoreDelay(color: color)
        colorView.color = color
    }
    
    // MARK: - ArcLevelViewDelegate
    
    func arcLevelColorResetClicked() {
        musicVisualizer.gradient = musicVisualizer.presets.defaultP.gradient
        centerCircleView.colorGradient = musicVisualizer.gradient
    }
    
    func arcLevelColorClicked(with event: NSEvent) {
        //
    }
    
}

enum AppState {
    case On
    case Off
}

