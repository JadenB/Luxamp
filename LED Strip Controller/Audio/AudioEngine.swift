//
//  AudioAnalyzer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

// https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation

import Foundation
import AudioKit
import AudioKitUI

let BUFFER_SIZE: Int = 1_024
let SAMPLE_RATE: Int = 44_100

class AudioEngine: BufferProcessorDelegate {
    
    var mic: AKMicrophone
    var silence: AKBooster
    var bufferSize: UInt32
    var bProcessor: BufferProcessor
    var refreshTimer: Timer
    let refreshRate: Double
    
    var delegate: AudioEngineDelegate?
    
    private var sendBufferNextCycle = false
    
    init(refreshRate: Double, bufferSize: UInt32 = 1_024) {
        self.bufferSize = bufferSize
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        silence = AKBooster(mic, gain: 0)
        AudioKit.output = silence
        
        self.refreshRate = refreshRate
        refreshTimer = Timer()
        
        bProcessor = BufferProcessor()
        bProcessor.delegate = self
    }
    
    private func setupBufferTap(onNode node: AKNode?) {
            node?.avAudioNode.installTap(
                onBus: 0,
                bufferSize: bufferSize,
                format: nil) { [weak self] (buffer, _) in
                    
                    guard let strongSelf = self else {
                        AKLog("Unable to create strong reference to self")
                        return
                    }
                    
                    buffer.frameLength = strongSelf.bufferSize
                    let offset = Int(buffer.frameCapacity - buffer.frameLength)
                    
                    if let tail = buffer.floatChannelData?[0] {
                        strongSelf.updateBuffer(tail + offset, withBufferSize: strongSelf.bufferSize)
                    }
            }
    }
    
    private func removeBufferTap(fromNode node: AKNode?) {
        node?.avAudioNode.removeTap(onBus: 0)
    }
    
    func start() {
        do {
            try AudioKit.start()
            setupBufferTap(onNode: mic)
            refreshTimer = Timer.scheduledTimer(timeInterval: 1.0/refreshRate, target: self, selector: #selector(getBuffer), userInfo: nil, repeats: true)
        } catch {
            print("AudioKit failed to start")
            return
        }
        
        
    }
    
    func stop() {
        do {
            removeBufferTap(fromNode: mic)
            refreshTimer.invalidate()
            refreshTimer = Timer()
            try AudioKit.stop()
        } catch {
            print("AudioKit failed to stop")
            return
        }
    }
    
    private func updateBuffer(_ buffer: UnsafeMutablePointer<Float>, withBufferSize size: UInt32) {
        if sendBufferNextCycle {
            sendBufferNextCycle = false
            let bufferArray = Array<Float>(UnsafeBufferPointer(start: buffer, count: Int(size)))
            bProcessor.process(buffer: bufferArray)
        }
    }
    
    @objc func getBuffer() {
        sendBufferNextCycle = true
    }
    
    func didFinishProcessingBuffer(_ bp: BufferProcessor) {
        delegate?.didRefreshAudioEngine(withProcessor: bp)
    }
}

protocol AudioEngineDelegate {
    func didRefreshAudioEngine(withProcessor p: BufferProcessor)
}
