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

class ViewController: NSViewController, AudioEngineBufferHandler, BufferProcessorDelegate {
    
    var audioEngine: AudioEngine!
    var bProcessor = BufferProcessor()
    
    var refreshTimer = Timer()
    
    @IBOutlet weak var spectrumView: SpectrumView!
    @IBOutlet weak var level1: LevelView!
    var levelIIR = BiasedIIRFilter(initialData: [0])
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioEngine = AudioEngine(bufferSize: UInt32(BUFFER_SIZE))
        
        spectrumView.backgroundColor = NSColor.black
        spectrumView.min = -48
        spectrumView.max = 4
        
        level1.min = 0
        level1.max = 1
        level1.backgroundColor = .black
        level1.color = .red
        
        levelIIR.upwardsAlpha = 0.7
        
        bProcessor.delegate = self
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        audioEngine.start()
        refreshTimer = Timer.scheduledTimer(timeInterval: 1.0/43.06640625, target: self, selector: #selector(updateSpec), userInfo: nil, repeats: true)
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        audioEngine.stop()
        refreshTimer.invalidate()
        refreshTimer = Timer()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func readFFTButtonPressed(_ sender: Any) {
        
    }
    
    @objc func updateSpec() {
        audioEngine.getBuffer(handler: self)
    }
    
    func didGetBuffer(buffer: [Float]) {
        self.bProcessor.process(buffer: buffer)
    }
    
    func didFinishProcessingBuffer(_ p: BufferProcessor) {
        DispatchQueue.main.async {
            self.spectrumView.updateSpectrum( spectrum: p.data )
            
            let level = self.levelIIR.applyFilter(toValue: p.gist.peakEnergy(), atIndex: 0)
            self.level1.updateLevel(level: level)
        }
    }

}

