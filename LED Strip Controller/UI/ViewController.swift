//
//  ViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa
import GistSwift

typealias AudioProcessor = BufferProcessor

class ViewController: NSViewController, AudioEngineDelegate, VisualizerOutputDelegate {
    
    var audioEngine: AudioEngine!
    var musicVisualizer: Visualizer!
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var totalAmpLevel: LevelView!
    @IBOutlet weak var colorView: NSColorWell!
    
    @IBOutlet weak var rateSliderLabel: NSTextField!
    
    @objc dynamic var manualButtonsEnabled = false
    @objc dynamic var isOn = false
    
    var currentMode: LightMode = .Pattern
    var hidden = true
    
    var levelIIR = BiasedIIRFilter(initialData: [0.0])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(refreshRate: 43.06640625)
        audioEngine.delegate = self
        musicVisualizer = Visualizer(withEngine: audioEngine)
        musicVisualizer.outputDelegate = self
        
        spectrumView.min = -48
        spectrumView.max = 4
        
        totalAmpLevel.min = -72
        totalAmpLevel.max = 2
        
        levelIIR.upwardsAlpha = 0.5
        levelIIR.downwardsAlpha = 0.8
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
        guard let visualizationController = segue.destinationController as? VisualizerMainViewController else { return }
        
        visualizationController.visualizer = musicVisualizer
    }
    
    @IBAction func rateSliderChanged(_ sender: NSSlider) {
        rateSliderLabel.stringValue = String(format: "%.1f", sender.floatValue)
    }
    
    @IBAction func offOnSegChanged(_ sender: NSSegmentedControl) {
        if (sender.selectedSegment == 1) == isOn {
            return
        }
        
        if sender.selectedSegment == 1 {
            isOn = true
            LightController.shared.turnOn()
        } else {
            isOn = false
            LightController.shared.turnOff()
        }
        
        manualButtonsEnabled = isOn && currentMode == .Pattern
        
        if isOn && currentMode == .Music {
            startAudioVisualization()
        } else if !isOn && currentMode == .Music {
            stopAudioVisualization()
        }
    }
    
    @IBAction func manualMusicSegChanged(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == currentMode.rawValue {
            return
        }
        
        currentMode = LightMode(rawValue: sender.selectedSegment)!
        manualButtonsEnabled = isOn && currentMode == .Pattern
        
        if currentMode == .Music {
            startAudioVisualization()
            LightController.shared.mode = .Music
        } else {
            stopAudioVisualization()
            LightController.shared.mode = .Pattern
        }
    }
    
    func startAudioVisualization() {
        audioEngine.start()
        spectrumView.enable()
        totalAmpLevel.enable()
    }
    
    func stopAudioVisualization() {
        audioEngine.stop()
        spectrumView.disable()
        totalAmpLevel.disable()
    }
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        if !isOn || currentMode != .Music {
            return
        }
        
        musicVisualizer.visualize()
        
        if !hidden {
            self.spectrumView.spectrum = p.spectrumDecibelData
            var level = max(p.amplitudeInDecibels(), self.totalAmpLevel.min)
            level = self.levelIIR.applyFilter(toValue: level, atIndex: 0)
            self.totalAmpLevel.level = level
        }
    }
    
    func didVisualizeIntoColor(_ color: NSColor) {
        LightController.shared.setColor(color: color)
        colorView.color = color
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

}

