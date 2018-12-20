//
//  AudioAnalyzer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation
import AudioKit
import AudioKitUI

class AudioReader {
    
    var mic: AKMicrophone
    var tracker: AKFrequencyTracker
    var silence: AKBooster
    
    var delegate: AudioReaderDelegate
    let updateFrequency: Double
    
    var updateTimer = Timer()
    
    init(updateFrequency: Double, delegate: AudioReaderDelegate) {
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        tracker = AKFrequencyTracker(mic)
        silence = AKBooster(tracker, gain: 0)
        AudioKit.output = silence
        
        self.updateFrequency = updateFrequency
        self.delegate = delegate
    }
    
    func start() {
        do {
            try AudioKit.start()
        } catch {
            print("AudioKit failed to start")
            return
        }
        
        DispatchQueue.main.async {
        
        self.updateTimer = Timer.scheduledTimer(timeInterval: 1 / self.updateFrequency,
                             target: self,
                             selector: #selector(self.update),
                             userInfo: nil,
                             repeats: true)
            
        }
    }
    
    func stop() {
        do {
            try AudioKit.stop()
        } catch {
            print("AudioKit failed to stop")
            return
        }
        
        updateTimer.invalidate()
        updateTimer = Timer()
    }
    
    @objc func update() {
        delegate.updateWithAudioData(frequency: tracker.frequency, amplitude: tracker.amplitude)
    }
}

protocol AudioReaderDelegate {
    func updateWithAudioData(frequency: Double, amplitude: Double)
}
