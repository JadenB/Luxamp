//
//  AudioEngine.swift
//  Luxamp
//
//  Created by Jaden Bernal on 9/18/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Foundation
import AVKit


let BUFFER_SIZE: Int = 1_024


class AudioEngine {
    
    weak var delegate: AudioEngineDelegate?
    
    private let avEngine: AVAudioEngine
    private var isTappingInput: Bool
    
    init() {
        avEngine = AVAudioEngine()
        isTappingInput = false
        NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationChange), name: .AVAudioEngineConfigurationChange, object: nil)
    }
    
    func startTappingInput() {
        if isTappingInput {
            return
        }
        
        let inputNode = avEngine.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)
        let sampleRateInt = Int(inputFormat.sampleRate)
        
        print("AudioEngine Input Format: \(inputFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(BUFFER_SIZE), format: inputFormat) { [weak self, sampleRate = sampleRateInt] (buffer, _) in
            guard let strongSelf = self else {
                print("Unable to create strong reference to self")
                return
            }
            
            buffer.frameLength = UInt32(BUFFER_SIZE)
            
            if let bufferTail = buffer.floatChannelData?[0] {
                let bufferPtr = UnsafeBufferPointer(start: bufferTail + Int(buffer.frameCapacity - buffer.frameLength), count: BUFFER_SIZE)
                strongSelf.handleBuffer([Float](bufferPtr), sampleRate: sampleRate)
            }
        }
        
        isTappingInput = true
        
        do {
            avEngine.prepare()
            try avEngine.start()
        } catch {
            print("AVAudioEngine unable to start!")
        }
    }
    
    func stopTappingInput() {
        if !isTappingInput {
            return
        }
        
        avEngine.stop()
        avEngine.inputNode.removeTap(onBus: 0)
        isTappingInput = false
    }
    
    var hasRunOnce = false
    
    private func handleBuffer(_ buffer: [Float], sampleRate: Int) {
        DispatchQueue.main.sync {
            let aBuffer = AnalyzedBuffer(buffer: buffer, bufferLength: BUFFER_SIZE, sampleRate: sampleRate)
            self.delegate?.didTapInput(withBuffer: aBuffer)
        }
    }
    
    @objc private func handleConfigurationChange(_ notification: Notification) {
        if !isTappingInput {
            return
        }
        
        stopTappingInput()
        avEngine.reset()
        startTappingInput()
    }
    
}


protocol AudioEngineDelegate: class {
    func didTapInput(withBuffer buffer: AnalyzedBuffer)
}

