//
//  AudioAnalyzer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

// https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation
//https://www.cocoawithlove.com/blog/2016/07/30/timer-problems.html#a-single-queue-synchronized-timer

import Foundation
import AVKit

let BUFFER_SIZE: Int = 1_024
let SAMPLE_RATE: Int = 41_000

class AudioEngine: BufferProcessorDelegate {
    weak var delegate: AudioEngineDelegate?
    
    let bProcessor = BufferProcessor()
    var isActive = false
    
    private var av = AVAudioEngine()
    private var refreshTimer: DispatchSourceTimer?
    private let refreshRate: Double
    
    private var sendBufferNextCycle = false
    private var audioDeviceChangedRanOnce = false
    
    init(refreshRate: Double) {
        self.refreshRate = refreshRate
        bProcessor.delegate = self
    }
    
    private func installBufferTap() {
        av.inputNode.installTap(
            onBus: 0,
            bufferSize: UInt32(BUFFER_SIZE),
            format: av.inputNode.inputFormat(forBus: 0)) { [weak self] (buffer, _) in
                
                guard let strongSelf = self else {
                    print("Unable to create strong reference to self")
                    return
                }
                
                buffer.frameLength = UInt32(BUFFER_SIZE)
                let offset = Int(buffer.frameCapacity - buffer.frameLength)
                
                if let tail = buffer.floatChannelData?[0] {
                    strongSelf.updateBuffer(tail + offset, withBufferSize: BUFFER_SIZE)
                }
        }
    }
    
    private func removeBufferTap() {
        av.inputNode.removeTap(onBus: 0)
    }
    
    func start() {
        if isActive { return }
        
        do {
            installBufferTap()
            av.prepare()
            try av.start()
            NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationChange), name: .AVAudioEngineConfigurationChange, object: av)
            isActive = true
            
            guard let timer = refreshTimer else {
                refreshTimer = DispatchSource.makeTimerSource()
                refreshTimer!.schedule(deadline: .now(), repeating: 1.0/refreshRate)
                refreshTimer!.setEventHandler(handler: { [weak self] in
                    guard let strongSelf = self else {
                        print("Unable to create strong reference to self")
                        return
                    }
                    strongSelf.getBuffer() })
                refreshTimer!.resume()
                return
            }
            
            timer.resume()
        } catch {
            print("AudioEngine failed to start")
            return
        }
        
    }
    
    func stop() {
        if !isActive { return }
        
        removeBufferTap()
        refreshTimer?.suspend()
        sendBufferNextCycle = false
        av.stop()
        NotificationCenter.default.removeObserver(self)
        isActive = false
    }
    
    @objc func handleConfigurationChange(_ notification: Notification) {
        print("audio configuration changed")
        audioDeviceChangedRanOnce = true
        if !audioDeviceChangedRanOnce {
            DispatchQueue.main.async {
                self.stop()
                self.delegate?.audioDeviceChanged()
            }
        }
    }
    
    @objc private func getBuffer() {
        sendBufferNextCycle = true
    }
    
    private func updateBuffer(_ buffer: UnsafeMutablePointer<Float>, withBufferSize size: Int) {
        if sendBufferNextCycle {
            sendBufferNextCycle = false
            let bufferArray = Array<Float>(UnsafeBufferPointer(start: buffer, count: size))
            bProcessor.process(buffer: bufferArray)
        }
    }
    
    // MARK: - BufferProcessorDelegate
    
    func didFinishProcessingBuffer(_ sender: BufferProcessor) {
        DispatchQueue.main.async {
            self.delegate?.didRefreshAudioEngine(withProcessor: sender)
        }
    }
}

protocol AudioEngineDelegate: class {
    func didRefreshAudioEngine(withProcessor p: BufferProcessor)
    func audioDeviceChanged()
}
