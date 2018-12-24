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
    
    var spectrumDecibelData: [Float] {
        get {
            return fftProcessor.data
        }
    }
    
    var spectrumMagnitudeData: [Float] {
        get {
            return gist.magnitudeSpectrum()
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
    
    func amplitudeInDecibels() -> Float {
        return fftProcessor.convertToDB(gist.peakEnergy())
    }
    
    func averageMagOfRange(_ range: Range<Int>, withFalloff falloff: Int) -> Float {
        var sum: Float = 0.0
        var denom: Float = Float(range.count)
        let magSpec = gist.magnitudeSpectrum()
        for i in range {
            sum += magSpec[i]
        }
        
        if falloff > 0 {
            
            let df: Float = 1.0 / (Float(falloff) + 1)
            var fallOffFactor = df * (Float(falloff) + 1)
            
            for i in 1...falloff {
                fallOffFactor -= df
                if range.startIndex - i >= 0 {
                    sum += magSpec[range.startIndex - i] * fallOffFactor
                    denom += fallOffFactor
                }
                if range.endIndex + i < magSpec.count {
                    sum += magSpec[range.endIndex + i] * fallOffFactor
                    denom += fallOffFactor
                }
            }
            
        }
        
        return sum / denom
    }
    
}

protocol BufferProcessorDelegate {
    func didFinishProcessingBuffer(_ bp: BufferProcessor)
}

