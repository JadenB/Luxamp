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

class ViewController: NSViewController, FFTProcessorDelegate {
    
    @IBOutlet weak var level1: LevelView!
    var audioReader: AudioEngine!
    var ffttap: AKFFTTap!
    var processor = FFTProcessor(buckets: 512)
    
    @IBOutlet weak var spectrumView: SpectrumView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioReader = AudioEngine(updateFrequency: 0)
        spectrumView.backgroundColor = NSColor.black
        
        level1.min = -72
        level1.max = 0
        level1.backgroundColor = .black
        level1.color = .red
        
        processor.delegate = self
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        audioReader.start()
        ffttap = AKFFTTap(audioReader.mic)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func readFFTButtonPressed(_ sender: Any) {
        Timer.scheduledTimer(timeInterval: 1.0/43.06640625, target: self, selector: #selector(updateSpec), userInfo: nil, repeats: true)
    }
    
    @objc func updateSpec() {
        processor.process(fft: ffttap.fftData)
    }
    
    func didFinishProcessingFFT(_ p: FFTProcessor) {
        spectrumView.updateSpectrum(spectrum: p.dbData)
        level1.updateLevel(level: p.dbData[0])
    }
    

}

