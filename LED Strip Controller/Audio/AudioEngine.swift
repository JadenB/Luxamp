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
    
    var bufferSize: UInt32
    var bProcessor: BufferProcessor
    var refreshTimer: DispatchSourceTimer?
    let refreshRate: Double
    
    let av = AVAudioEngine()
    
    var delegate: AudioEngineDelegate?
    
    private var sendBufferNextCycle = false
    
    init(refreshRate: Double, bufferSize: UInt32 = 1_024) {
        self.bufferSize = bufferSize
        self.refreshRate = refreshRate
        
        bProcessor = BufferProcessor(bufferSize: BUFFER_SIZE)
        bProcessor.delegate = self
    }
    
    private func setupBufferTap() {
        av.inputNode.installTap(
            onBus: 0,
            bufferSize: bufferSize,
            format: nil) { [weak self] (buffer, _) in
                
                guard let strongSelf = self else {
                    print("Unable to create strong reference to self")
                    return
                }
                
                buffer.frameLength = strongSelf.bufferSize
                let offset = Int(buffer.frameCapacity - buffer.frameLength)
                
                if let tail = buffer.floatChannelData?[0] {
                    strongSelf.updateBuffer(tail + offset, withBufferSize: strongSelf.bufferSize)
                }
        }
    }
    
    private func removeBufferTap() {
        av.inputNode.removeTap(onBus: 0)
    }
    
    func start() {
        do {
            setupBufferTap()
            av.prepare()
            try av.start()
            
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
        removeBufferTap()
        refreshTimer?.suspend()
        sendBufferNextCycle = false
        av.stop()
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
        DispatchQueue.main.async {
            self.delegate?.didRefreshAudioEngine(withProcessor: bp)
        }
    }
}

protocol AudioEngineDelegate {
    func didRefreshAudioEngine(withProcessor p: BufferProcessor)
}
