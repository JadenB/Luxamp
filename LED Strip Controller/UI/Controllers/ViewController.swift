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
    
    @IBOutlet weak var powerButton: NSButton!
    @IBOutlet weak var spectrum: SpectrumView!
    
    @IBOutlet weak var centerCircleView: ArcLevelView!
    @IBOutlet weak var colorView: CircularColorWell!
    
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
    
    func startAudioVisualization() {
        audioEngine.start()
    }
    
    func stopAudioVisualization() {
        audioEngine.stop()
    }
    
    // MARK: - AudioEngineDelegate
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        if state == .Off {
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

