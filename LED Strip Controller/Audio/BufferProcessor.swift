//
//  BufferProcessor.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/22/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation
import GistSwift

class BufferProcessor {
    let gist = Gist(frameSize: BUFFER_SIZE, sampleRate: SAMPLE_RATE)
    var delegate: BufferProcessorDelegate?
    
    let fftSize: Int
    var spectrumDecibelData: [Float]
    
    var spectrumMagnitudeData: [Float] {
        get {
            return gist.magnitudeSpectrum()
        }
    }
    
    var filter: BiasedIIRFilter
    
    var useAWeighting = false
    var useWindowing = false
    var useIIRFilter = true
    var shouldConvertToDb = true
    
    private let aWeightFrequency: [Float] = [
        10, 12.5, 16, 20,
        25, 31.5, 40, 50,
        63, 80, 100, 125,
        160, 200, 250, 315,
        400, 500, 630, 800,
        1000, 1250, 1600, 2000,
        2500, 3150, 4000, 5000,
        6300, 8000, 10000, 12500,
        16000, 20000
    ]
    
    private let aWeightDecibels: [Float] = [
        -70.4, -63.4, -56.7, -50.5,
        -44.7, -39.4, -34.6, -30.2,
        -26.2, -22.5, -19.1, -16.1,
        -13.4, -10.9, -8.6, -6.6,
        -4.8, -3.2, -1.9, -0.8,
        0.0, 0.6, 1.0, 1.2,
        1.3, 1.2, 1.0, 0.5,
        -0.1, -1.1, -2.5, -4.3,
        -6.6, -9.3
    ]
    
    init(bufferSize: Int) {
        fftSize = bufferSize / 2
        spectrumDecibelData = Array<Float>(repeating: 0.0, count: fftSize)
        filter = BiasedIIRFilter(size: fftSize)
        filter.upwardsAlpha = 0.4
        filter.downwardsAlpha = 0.7
    }
    
    func process(buffer: [Float]) {
        gist.processAudio(frame: buffer)
        var result = normalizeFFT(gist.magnitudeSpectrum())
        
        if useIIRFilter {
            filter.applyFilter(toData: &result)
        }
        
        if useWindowing {
            applyHanningWindow(&result)
        }
        
        if shouldConvertToDb {
            applyDbConversion(fftSize, &result)
        }
        
        spectrumDecibelData = result
        delegate?.didFinishProcessingBuffer(self)
    }
    
    func normalizeFFT(_ fft: [Float]) -> [Float] {
        var result = fft
        let normFactor = 2 / Float(fftSize)
        
        for i in 0..<fft.count {
            result[i] = fft[i] * normFactor
        }
        
        return result
    }
    
    func convertToDB(_ value: Float) -> Float {
        return 20 * log10(value)
    }
    
    func aWeightedValue(dbValue: Float, freq: Float) -> Float {
        if freq < aWeightFrequency[0] {
            return dbValue + aWeightDecibels[0]
        } else if freq > aWeightFrequency[aWeightFrequency.count - 1] {
            return dbValue + aWeightDecibels[aWeightFrequency.count - 1]
        }
        
        for i in 1..<aWeightFrequency.count {
            if(aWeightFrequency[i] > freq) {
                // interpolate linearly between known frequencies
                return dbValue + aWeightDecibels[i-1] + (freq - aWeightFrequency[i-1]) *
                    (aWeightDecibels[i] - aWeightDecibels[i-1]) / (aWeightFrequency[i] - aWeightFrequency[i-1])
            }
        }
        
        return 0.0
    }
    
    private func applyDbConversion(_ fftSize: Int, _ data: inout [Float]) {
        var frequency: Float = 0
        let df: Float = Float(SAMPLE_RATE) / Float(fftSize * 2)
        for i in 0..<fftSize {
            data[i] = convertToDB(data[i])
            
            if useAWeighting {
                data[i] = aWeightedValue(dbValue: data[i], freq: frequency)
                frequency += df
            }
        }
    }
    
    private func applyHanningWindow(_ data: inout [Float]) {
        for i in 0..<data.count {
            data[i] = data[i] * 0.5 * (1.0 - cos(2.0 * Float.pi * Float(i) / Float(data.count)))
        }
    }
    
    func amplitudeInDecibels() -> Float {
        return convertToDB(gist.peakEnergy())
    }
    
    func averageMagOfRange(_ range: ClosedRange<Int>, withFalloff falloff: Int) -> Float {
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
                if range.lowerBound - i >= 0 {
                    sum += magSpec[range.lowerBound - i] * fallOffFactor
                    denom += fallOffFactor
                }
                if range.upperBound + i < magSpec.count {
                    sum += magSpec[range.upperBound + i] * fallOffFactor
                    denom += fallOffFactor
                }
            }
            
        }
        
        return sum / denom
    } // averageMagOfRange
    
}

protocol BufferProcessorDelegate {
    func didFinishProcessingBuffer(_ bp: BufferProcessor)
}
