//
//  FFTProcessor.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/21/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation

class FFTProcessor {
    
    let fftSize: Int
    private var fftData: [Float]
    var data: [Float]
    
    var delegate: FFTProcessorDelegate?
    
    var useAWeighting = false
    var useWindowing = false
    var useIIRFilter = true
    var shouldConvertToDb = true
    var smoothingFactor = 1
    
    private var iirFilter: BiasedIIRFilter
    
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
    
    init(buckets: Int) {
        fftSize = buckets
        fftData = Array<Float>(repeating: 0.0, count: fftSize)
        data = Array<Float>(repeating: 0.0, count: fftSize)
        iirFilter = BiasedIIRFilter(initialData: fftData)
        iirFilter.upwardsAlpha = 0.4
        iirFilter.downwardsAlpha = 0.7
    }
    
    func process(fft: [Float]) {
        var result = normalizeFFT(fft)
        
        if useIIRFilter {
            iirFilter.applyFilter(toData: &result)
        }
        
        if smoothingFactor > 1 {
            applySmooth(&result)
        }
        
        if useWindowing {
            applyHanningWindow(&result)
        }
        
        fftData = result

        if shouldConvertToDb {
            applyDbConversion(fftSize, &result)
        }
        
        data = result
        delegate?.didFinishProcessingFFT(self)
    }
    
    private func applySmooth(_ data: inout [Float]) {
        for i in stride(from: smoothingFactor, to: data.count, by: smoothingFactor) {
            let x0 = i - smoothingFactor
            let x1 = i
            
            var maxx: Float = 0
            for j in x0..<x1 {
                maxx = max(maxx, data[j])
            }
            
            data[x0] = maxx
            
        }
        
        for i in stride(from: smoothingFactor, to: data.count, by: smoothingFactor) {
            let x0 = i - smoothingFactor
            let x1 = i
            let y0 = data[x0]
            let y1 = data[x1]
            
            for j in x0..<x1 {
                let mu: Float = Float(j - x0) / Float(smoothingFactor)
                let mu2 = (1-cos(mu*Float.pi))/2;
                data[j] = y0*(1-mu2)+y1*mu2
            }
            
        }
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
    
    func applyAWeightingToDb(value: Float, freq: Float) -> Float {
        if freq < aWeightFrequency[0] {
            return value + aWeightDecibels[0]
        } else if freq > aWeightFrequency[aWeightFrequency.count - 1] {
            return value + aWeightDecibels[aWeightFrequency.count - 1]
        }
        
        for i in 1..<aWeightFrequency.count {
            if(aWeightFrequency[i] > freq) {
                // interpolate linearly between known frequencies
                return value + aWeightDecibels[i-1] + (freq - aWeightFrequency[i-1]) *
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
                data[i] = applyAWeightingToDb(value: data[i], freq: frequency)
                frequency += df
            }
        }
    }
    
    private func applyHanningWindow(_ data: inout [Float]) {
        for i in 0..<data.count {
            data[i] = data[i] * 0.5 * (1.0 - cos(2.0 * Float.pi * Float(i) / Float(data.count)))
        }
    }
    
    
}

protocol FFTProcessorDelegate {
    func didFinishProcessingFFT(_ p: FFTProcessor)
}
