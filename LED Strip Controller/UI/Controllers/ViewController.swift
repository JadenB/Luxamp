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
    
    var audioEngine: AudioEngine!
    var musicVisualizer: Visualizer!
    var patternManager = LightPatternManager()
    
    @IBOutlet weak var modeSeg: NSSegmentedControl!
    @IBOutlet weak var powerButton: NSButton!
    @IBOutlet weak var spectrum: SpectrumView!
    
    @IBOutlet weak var centerCircleView: ArcLevelView!
    @IBOutlet weak var colorView: CircularColorWell!
    
    @objc dynamic var manualButtonsEnabled = false
    @objc dynamic var modeSegEnabled = false
    
    var hidden = true
    
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
        audioEngine = AudioEngine(refreshRate: Double(SAMPLE_RATE) / Double(BUFFER_SIZE))
        audioEngine.delegate = self
        musicVisualizer = Visualizer(withEngine: audioEngine)
        musicVisualizer.outputDelegate = self
        patternManager.delegate = self
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
        LightController.shared.setColorIgnoreDelay(color: sender.color)
    }
    
    @IBAction func powerButtonPressed(_ sender: NSButton) {
        let newState: AppState = (sender.state == .on) ? .On : .Off
        if newState == state {
            return // don't run if reselecting same segement
        } else {
            state = newState
        }
        
        if state == .On {
            LightController.shared.turnOn()
            LightController.shared.setColorIgnoreDelay(color: colorView.color)
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
    
    func startAudioVisualization() {
        audioEngine.start()
    }
    
    func stopAudioVisualization() {
        audioEngine.stop()
    }
    
    // MARK: - AudioEngineDelegate
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        if state == .Off || mode != .Music {
            return
        }
        
        var visualSpectrum = [Float](repeating: 0, count: 255)
        let vsCountf = Float(visualSpectrum.count)
        
        for i in 0..<visualSpectrum.count {
            let spectrumIndex = Int( Float(p.spectrumDecibelData.count) * (log2f(vsCountf) - log2f(vsCountf - Float(i))) /  log2f(1 + vsCountf) )
            visualSpectrum[i] = p.spectrumDecibelData[spectrumIndex]
        }
        
        spectrum.spectrum = visualSpectrum
        musicVisualizer.visualize()
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
        if mode == .Music {
            LightController.shared.setColor(color: color)
            colorView.color = color
        }
        
        centerCircleView.setBrightnessLevel(to: brightnessVal)
        centerCircleView.setColorLevel(to: colorVal)
    }
    
    // MARK: - LightPatternManagerDelegate
    
    func didGenerateColorFromPattern(_ color: NSColor) {
        if mode == .Pattern {
            LightController.shared.setColorIgnoreDelay(color: color)
            colorView.color = color
        }
    }
    
    @IBOutlet weak var smoothingView: SmoothingView!
    @IBAction func smoothingslider(_ sender: NSSlider) {
        smoothingView.smoothing = CGFloat(sender.floatValue)
    }
    
    // MARK: - ArcLevelViewDelegate
    
    func arcLevelColorResetClicked() {
        //
    }
    
    func arcLevelColorClicked(with event: NSEvent) {
        //
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

