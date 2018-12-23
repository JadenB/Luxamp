//
//  BufferProcessor.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/22/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation
import GistSwift

class BufferProcessor: FFTProcessorDelegate {
    let fftProcessor = FFTProcessor(buckets: BUFFER_SIZE / 2)
    let gist = Gist(frameSize: BUFFER_SIZE, sampleRate: SAMPLE_RATE)
    var delegate: BufferProcessorDelegate?
    
    var data: [Float] {
        get {
            return fftProcessor.data
        }
    }
    
    init() {
        fftProcessor.delegate = self
        fftProcessor.shouldConvertToDb = true
        fftProcessor.smoothingFactor = 1
    }
    
    func process(buffer: [Float]) {
        gist.processAudio(frame: buffer)
        fftProcessor.process(fft: gist.magnitudeSpectrum())
    }
    
    func didFinishProcessingFFT(_ p: FFTProcessor) {
        delegate?.didFinishProcessingBuffer(self)
    }
    
}

protocol BufferProcessorDelegate {
    func didFinishProcessingBuffer(_ p: BufferProcessor)
}

