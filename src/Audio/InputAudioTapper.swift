//
//  AudioEngine.swift
//  Luxamp
//
//  Created by Jaden Bernal on 9/18/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Foundation
import AVKit


final class InputAudioTapper {
	static let BUFFER_SIZE: Int = 1_024
    
    private let avEngine = AVAudioEngine()
	private var onTap: ([Float]) -> Void = {_ in }
    
	init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleConfigurationChange), name: .AVAudioEngineConfigurationChange, object: nil)
    }
	
	func setOnTap(_ block: @escaping ([Float]) -> Void) {
		onTap = block;
	}
    
    func startTappingInput() {
		avEngine.stop()
		avEngine.reset()
		
        let inputNode = avEngine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        
        print("AudioEngine Input Format: \(inputFormat)")
        
		inputNode.installTap(onBus: 0, bufferSize: UInt32(InputAudioTapper.BUFFER_SIZE), format: inputFormat) { [weak self] (buffer, _) in
            guard let strongSelf = self else {
                return
            }

			buffer.frameLength = UInt32(InputAudioTapper.BUFFER_SIZE)

            if let bufferTail = buffer.floatChannelData?[0] {
				let bufferPtr = UnsafeBufferPointer(start: bufferTail + Int(buffer.frameCapacity - buffer.frameLength), count: InputAudioTapper.BUFFER_SIZE)
				
				strongSelf.onTap([Float](bufferPtr))
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
    
    @objc private func handleConfigurationChange(_ notification: Notification) {
        stopTappingInput()
        startTappingInput()
    }
    
}
