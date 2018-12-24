//
//  ViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa
import AudioKit
import AudioKitUI
import GistSwift

typealias AudioProcessor = BufferProcessor

class ViewController: NSViewController, AudioEngineDelegate {
    
    var audioEngine: AudioEngine!
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var totalAmpLevel: LevelView!
    @IBOutlet weak var totalAmpLabel: NSTextField!
    @IBOutlet weak var colorView: NSColorWell!
    
    var levelIIR = BiasedIIRFilter(initialData: [0.0])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(refreshRate: 43.06640625, bufferSize: UInt32(BUFFER_SIZE))
        audioEngine.delegate = self
        
        spectrumView.backgroundColor = .black
        spectrumView.color = .red
        spectrumView.min = -48
        spectrumView.max = 4
        
        totalAmpLevel.min = -72
        totalAmpLevel.max = 2
        totalAmpLevel.backgroundColor = .black
        totalAmpLevel.color = .red
        
        levelIIR.upwardsAlpha = 0.5
        levelIIR.downwardsAlpha = 0.8
        
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        audioEngine.start()
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        audioEngine.stop()
    }
    
    func didRefreshAudioEngine(withProcessor p: BufferProcessor) {
        DispatchQueue.main.async {
            self.spectrumView.updateSpectrum( spectrum: p.spectrumDecibelData )
            
            var level = max(p.amplitudeInDecibels(), self.totalAmpLevel.min)
            level = self.levelIIR.applyFilter(toValue: level, atIndex: 0)
            self.totalAmpLevel.updateLevel(level: level)
            self.totalAmpLabel.stringValue = String(format: "%.1f", level)
        }
    }

}

