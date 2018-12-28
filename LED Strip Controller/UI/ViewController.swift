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
    var lightController: LightController!
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var totalAmpLevel: LevelView!
    @IBOutlet weak var totalAmpLabel: NSTextField!
    @IBOutlet weak var colorView: NSColorWell!
    
    @IBOutlet weak var rateSliderLabel: NSTextField!
    
    @objc dynamic var manualButtonsEnabled = false
    @objc dynamic var isOn = false
    
    var currentMode: Mode = .Manual
    var hidden = true
    
    var levelIIR = BiasedIIRFilter(initialData: [0.0])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(refreshRate: 43.06640625, bufferSize: UInt32(BUFFER_SIZE))
        audioEngine.delegate = self
        musicVisualizer = Visualizer(withEngine: audioEngine)
        musicVisualizer.delegate = self
        
        lightController = LightController(refreshRate: 60.0)
        
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
        guard let visualizationController = segue.destinationController as? VisualizerSettingsViewController else { return }
        
        visualizationController.visualizer = musicVisualizer
    }
    
    @IBAction func rateSliderChanged(_ sender: NSSlider) {
        rateSliderLabel.stringValue = String(format: "%.1f", sender.floatValue)
    }
    
    @IBAction func offOnSegChanged(_ sender: NSSegmentedControl) {
        if (sender.selectedSegment == 1) == isOn {
            return
        }
        
        isOn = (sender.selectedSegment == 1)
        manualButtonsEnabled = isOn && currentMode == .Manual
        
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
        
        currentMode = Mode(rawValue: sender.selectedSegment)!
        manualButtonsEnabled = isOn && currentMode == .Manual
        
        if currentMode == .Music {
            startAudioVisualization()
        } else {
            stopAudioVisualization()
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
        totalAmpLabel.stringValue = "0.0"
    }
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        if !isOn || currentMode != .Music {
            return
        }
        
        musicVisualizer.visualize()
        
        if !hidden {
            self.spectrumView.updateSpectrum( spectrum: p.spectrumDecibelData )
            var level = max(p.amplitudeInDecibels(), self.totalAmpLevel.min)
            level = self.levelIIR.applyFilter(toValue: level, atIndex: 0)
            self.totalAmpLevel.updateLevel(level: level)
            self.totalAmpLabel.stringValue = String(format: "%.1f", level)
        }
    }
    
    func didVisualizeIntoColor(_ color: NSColor) {
        colorView.color = color
        lightController.setColor(color: color)
    }

}

enum Mode: Int {
    case Manual = 0
    case Music = 1
}
