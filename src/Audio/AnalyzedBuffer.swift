//
//  AnalyzedBuffer.swift
//  Luxamp
//
//  Created by Jaden Bernal on 9/19/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Foundation
import GistSwift


class AnalyzedBuffer {
    private static let aWeightFrequency: [Float] = [
        10, 12.5, 16, 20,
        25, 31.5, 40, 50,
        63, 80, 100, 125,
        160, 200, 250, 315,
        400, 500, 630, 800,
        1000, 1250, 1600, 2000,
        2500, 3150, 4000, 5000,
        6300, 8000, 10000, 12500,
        16000, 20000 ]
    private static let aWeightDecibels: [Float] = [
        -70.4, -63.4, -56.7, -50.5,
        -44.7, -39.4, -34.6, -30.2,
        -26.2, -22.5, -19.1, -16.1,
        -13.4, -10.9, -8.6, -6.6,
        -4.8, -3.2, -1.9, -0.8,
        0.0, 0.6, 1.0, 1.2,
        1.3, 1.2, 1.0, 0.5,
        -0.1, -1.1, -2.5, -4.3,
        -6.6, -9.3 ]
    
    private let fftSize: Int
    let gist: Gist
    
    init(buffer: [Float], bufferLength: Int, sampleRate: Int) {
        gist = Gist(frameSize: bufferLength, sampleRate: 44100)
        fftSize = bufferLength / 2
        
        gist.processAudio(frame: buffer)
    }
    
    /// Normalizes the absolute magnitude of the frequency buckets produced by the FFT so they can later be converted to decibels
    ///
    /// - Parameter fft: The frequency buckets produced by the FFT
    private func normalizeFFT(_ fft: inout [Float]) {
        let normFactor = 2 / Float(fftSize)
        
        for i in 0..<fft.count {
            fft[i] = fft[i] * normFactor
        }
    }
    
    /// Converts a single normalized magnitude to decibels
    ///
    /// - Parameter value: The normalized magnitude
    /// - Returns: The decibel value of the input magnitude
    private func convertToDB(_ value: Float) -> Float {
        return 20 * log10(value)
    }
    
    func visualSpectrum() -> [Float] {
        var visualSpectrum = gist.melFrequencySpectrum()
        normalizeFFT(&visualSpectrum)
        
        for i in 0..<visualSpectrum.count {
            visualSpectrum[i] = convertToDB(visualSpectrum[i]) - 40 * Float(visualSpectrum.count - i / 3) / Float(visualSpectrum.count)
        }
        
        return visualSpectrum
    }
    
    /// Gets the average magnitude of the frequency spectrum in the given frequency bucket range
    ///
    /// - Parameters:
    ///   - range: The frequency buckets to average
    ///   - falloff: The number of buckets on each side of the range to average with less weight as they get farther from the range
    /// - Returns: The average magnitude of the given range, with silence being 0.0
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
