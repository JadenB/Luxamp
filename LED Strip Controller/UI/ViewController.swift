//
//  ViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa
import GistSwift

class ViewController: NSViewController, AudioEngineDelegate, VisualizerOutputDelegate, LightPatternManagerDelegate {
    
    var audioEngine: AudioEngine!
    var musicVisualizer: Visualizer!
    var patternManager = LightPatternManager()
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var totalAmpLevel: LevelView!
    @IBOutlet weak var colorView: NSColorWell!
    
    @IBOutlet weak var onOffSeg: NSSegmentedControl!
    @IBOutlet weak var modeSeg: NSSegmentedControl!
    
    @IBOutlet weak var rateSlider: NSSlider!
    @IBOutlet weak var rateSliderLabel: NSTextField!
    
    @objc dynamic var manualButtonsEnabled = false
    @objc dynamic var modeSegEnabled = false
    
    var hidden = true
    var levelIIR = BiasedIIRFilter(initialData: [0.0])
    
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
    
    var mode: AppMode = .Constant {
        didSet {
            patternManager.stop()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(refreshRate: 43.06640625)
        audioEngine.delegate = self
        musicVisualizer = Visualizer(withEngine: audioEngine)
        musicVisualizer.outputDelegate = self
        patternManager.delegate = self
        
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
    
    @IBAction func colorWellChanged(_ sender: NSColorWell) {
        mode = .Constant
        LightController.shared.setColor(color: sender.color)
    }
    
    @IBAction func rateSliderChanged(_ sender: NSSlider) {
        rateSliderLabel.stringValue = String(format: "%.1f s", sender.floatValue)
        patternManager.start(withPattern: patternManager.pattern, andPeriod: sender.doubleValue)
    }
    
    @IBAction func offOnSegChanged(_ sender: NSSegmentedControl) {
        let newState: AppState = (onOffSeg.selectedSegment == 1) ? .On : .Off
        if newState == state {
            return // don't run if reselecting same segement
        } else {
            state = newState
        }
        
        if state == .On {
            LightController.shared.turnOn()
        } else {
            LightController.shared.turnOff()
        }
        
        manualButtonsEnabled = (state == .On && mode != .Music)
        modeSegEnabled = (state == .On)
        
        if state == .On && mode == .Music {
            startAudioVisualization()
        } else if state == .Off && mode == .Music {
            stopAudioVisualization()
        }
    }
    
    @IBAction func manualMusicSegChanged(_ sender: NSSegmentedControl) {
        let newMode: AppMode = (sender.selectedSegment == 0) ? .Constant : .Music
        if newMode == mode {
            return // don't run if reselecting segment (switches to constant if a pattern is running and 'Manual' is pressed again)
        } else {
            mode = newMode
        }
        
        
        manualButtonsEnabled = (state == .On && mode != .Music)
        
        if state == .On && mode == .Music {
            startAudioVisualization()
        } else if state == .On && mode != .Music {
            stopAudioVisualization()
        }
    }
    
    @IBAction func strobePressed(_ sender: NSButton) {
        mode = .Pattern
        patternManager.start(withPattern: .Strobe, andPeriod: rateSlider.doubleValue)
    }
    
    @IBAction func fadePressed(_ sender: NSButton) {
        mode = .Pattern
        patternManager.start(withPattern: .Fade, andPeriod: rateSlider.doubleValue)
    }
    
    @IBAction func jumpPressed(_ sender: NSButton) {
        mode = .Pattern
        patternManager.start(withPattern: .Jump, andPeriod: rateSlider.doubleValue)
    }
    
    @IBAction func candlePressed(_ sender: NSButton) {
        mode = .Pattern
        patternManager.start(withPattern: .Candle, andPeriod: rateSlider.doubleValue)
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
    
    // MARK: - AudioEngineDelegate
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        if state == .Off || mode != .Music {
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
    
    func didVisualizeIntoColor(_ color: NSColor) {
        if mode == .Music {
            LightController.shared.setColor(color: color)
            colorView.color = color
        }
    }

    // MARK: - LightPatternManagerDelegate
    
    func didGenerateColorFromPattern(_ color: NSColor) {
        if mode == .Pattern {
            LightController.shared.setColorIgnoreDelay(color: color)
            colorView.color = color
        }
    }
    
}

enum AppState {
    case On
    case Off
}

enum AppMode {
    case Constant
    case Pattern
    case Music
}

