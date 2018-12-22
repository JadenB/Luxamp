//
//  FFTProcessor.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/21/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation

let SAMPLE_RATE: Double = 44_100

class FFTProcessor {
    
    let aWeightFrequency: [Double] = [
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
    
    let aWeightDecibels: [Double] = [
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
    
    let fftSize: Int
    private var lastIIR: [Double]
    var fftData: [Double]
    var dbData: [Double]
    
    var delegate: FFTProcessorDelegate?
    
    var useAWeighting = true
    var useWindowing = false
    
    var useIIRFilter = true
    var IIRAlpha = 0.6
    
    var smoothingFactor = 1
    
    init(buckets: Int) {
        fftSize = buckets
        lastIIR = Array<Double>(repeating: 0.0, count: fftSize)
        fftData = lastIIR
        dbData = lastIIR
    }
    
    func process(fft: [Double]) {
        var result = fft
        
        if useIIRFilter {
            applyIIRFilter(&result)
        }
        
        if smoothingFactor >= 1 {
            applySmooth(&result)
        }
        
        if useWindowing {
            applyHanningWindow(&result)
        }
        
        fftData = result
        applyDbConversion(fftSize, &result)
        dbData = result
        delegate?.didFinishProcessingFFT(self)
    }
    
    private func applyIIRFilter(_ data: inout [Double]) {
        for i in 0..<fftSize {
            //data[i] = IIRAlpha * lastIIR[i] + (1 - IIRAlpha) * data[i]
            data[i] = max(IIRAlpha * lastIIR[i] + (1 - IIRAlpha) * data[i], data[i])
            lastIIR[i] = data[i]
        }
    }
    
    private func applySmooth(_ data: inout [Double]) {
        for i in stride(from: smoothingFactor, to: data.count, by: smoothingFactor) {
            let x0 = i - smoothingFactor
            let x1 = i
            
            var maxx: Double = 0
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
                let mu: Double = Double(j - x0) / Double(smoothingFactor)
                let mu2 = (1-cos(mu*Double.pi))/2;
                data[j] = y0*(1-mu2)+y1*mu2
            }
            
        }
    }
    
    func convertToDB(_ value: Double) -> Double {
        return 20 * log10(value)
    }
    
    func applyAWeightingToDb(value: Double, freq: Double) -> Double {
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
    
    private func applyDbConversion(_ fftSize: Int, _ data: inout [Double]) {
        var frequency: Double = 0
        let df: Double = SAMPLE_RATE / Double(fftSize * 2)
        for i in 0..<fftSize {
            data[i] = convertToDB(data[i])
            
            if useAWeighting {
                data[i] = applyAWeightingToDb(value: data[i], freq: frequency)
                frequency += df
            }
        }
    }
    
    private func applyHanningWindow(_ data: inout [Double]) {
        for i in 0..<data.count {
            data[i] = data[i] * 0.5 * (1.0 - cos(2.0 * Double.pi * Double(i) / Double(data.count)))
        }
    }
    
    
}

protocol FFTProcessorDelegate {
    func didFinishProcessingFFT(_ p: FFTProcessor)
}
