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
    
    private let avEngine = AVAudioEngine()
	private var currentBuffer = [Float](repeating: 0.0, count: BUFFER_SIZE)
	private var currentBufferLock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
	init() {
		pthread_mutex_init(currentBufferLock, nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationChange), name: .AVAudioEngineConfigurationChange, object: nil)
    }
	
	deinit {
		currentBufferLock.deallocate()
	}
    
    func startTappingInput() {
		avEngine.stop()
		avEngine.reset()
		
        let inputNode = avEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        print("AudioEngine Input Format: \(inputFormat)")
        
        inputNode.installTap(onBus: 0, bufferSize: UInt32(BUFFER_SIZE), format: inputFormat) { [weak self] (buffer, _) in
            guard let strongSelf = self else {
                return
            }

            buffer.frameLength = UInt32(BUFFER_SIZE)

            if let bufferTail = buffer.floatChannelData?[0] {
                let bufferPtr = UnsafeBufferPointer(start: bufferTail + Int(buffer.frameCapacity - buffer.frameLength), count: BUFFER_SIZE)
				pthread_mutex_lock(strongSelf.currentBufferLock)
				strongSelf.currentBuffer = [Float](bufferPtr)
				pthread_mutex_unlock(strongSelf.currentBufferLock)
            }
        }
        
        do {
            avEngine.prepare()
            try avEngine.start()
        } catch {
			inputNode.removeTap(onBus: 0)
            print("AVAudioEngine unable to start!")
        }
    }
    
    func stopTappingInput() {
		avEngine.inputNode.removeTap(onBus: 0)
		avEngine.stop()
    }
	
	func getCurrentBuffer() -> [Float] {
		pthread_mutex_lock(currentBufferLock)
		let copiedBuffer = currentBuffer
		pthread_mutex_unlock(currentBufferLock)
		return copiedBuffer
	}
    
    @objc private func handleConfigurationChange(_ notification: Notification) {
        stopTappingInput()
        startTappingInput()
    }
    
}
