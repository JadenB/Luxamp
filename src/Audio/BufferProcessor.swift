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
    weak var delegate: BufferProcessorDelegate?
    
    /// The volume in decibels of each frequency bucket produced by the FFT
    var spectrumDecibelData: [Float]
    let gist = Gist(frameSize: Int(BUFFER_SIZE), sampleRate: 44100)
    
    /// The absolute magnitudes of each frequency bucket produced by the FFT
    var spectrumMagnitudeData: [Float] {
        get {
            return gist.magnitudeSpectrum()
        }
    }
    
    var spectrumNormalizedMagnitudeData: [Float]
    
    var useAWeighting = false
    var useWindowing = false
    var shouldConvertToDb = true
    
    private let fftSize: Int = Int(BUFFER_SIZE) / 2
    private let aWeightFrequency: [Float] = [
        10, 12.5, 16, 20,
        25, 31.5, 40, 50,
        63, 80, 100, 125,
        160, 200, 250, 315,
        400, 500, 630, 800,
        1000, 1250, 1600, 2000,
        2500, 3150, 4000, 5000,
        6300, 8000, 10000, 12500,
        16000, 20000 ]
    private let aWeightDecibels: [Float] = [
        -70.4, -63.4, -56.7, -50.5,
        -44.7, -39.4, -34.6, -30.2,
        -26.2, -22.5, -19.1, -16.1,
        -13.4, -10.9, -8.6, -6.6,
        -4.8, -3.2, -1.9, -0.8,
        0.0, 0.6, 1.0, 1.2,
        1.3, 1.2, 1.0, 0.5,
        -0.1, -1.1, -2.5, -4.3,
        -6.6, -9.3 ]
    
    init() {
        spectrumDecibelData = Array<Float>(repeating: 0.0, count: fftSize)
        spectrumNormalizedMagnitudeData = Array<Float>(repeating: 0.0, count: fftSize)
    }
    
    /// Converts audio into a frequency spectrum
    ///
    /// - Parameter buffer: The audio buffer to process
    func process(buffer: [Float]) {
        gist.processAudio(frame: buffer)
        var result = normalizeFFT(gist.magnitudeSpectrum())
        spectrumNormalizedMagnitudeData = result // save the normalized spectrum data for later access
        
        if useWindowing {
            applyHanningWindow(&result)
        }
        
        if shouldConvertToDb {
            applyDbConversion(&result)
        }
        
        spectrumDecibelData = result
        delegate?.bufferProcessorFinishedProcessing(self)
    }
    
    /// Gets the peak volume in decibels of the last processed buffer
    ///
    /// - Returns: The volume in decibels
    func amplitudeInDecibels() -> Float {
        return convertToDB(gist.peakEnergy())
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
    
    /// Normalizes the absolute magnitude of the frequency buckets produced by the FFT so they can later be converted to decibels
    ///
    /// - Parameter fft: The frequency buckets produced by the FFT
    /// - Returns: The normalized frequency buckets
    private func normalizeFFT(_ fft: [Float]) -> [Float] {
        var result = fft
        let normFactor = 2 / Float(fftSize)
        
        for i in 0..<fft.count {
            result[i] = fft[i] * normFactor
        }
        
        return result
    }
    
    /// Converts a single normalized magnitude to decibels
    ///
    /// - Parameter value: The normalized magnitude
    /// - Returns: The decibel value of the input magnitude
    private func convertToDB(_ value: Float) -> Float {
        return 20 * log10(value)
    }
    
    /// Applys standard A-weighting to a single decibel value according to its frequency
    ///
    /// - Parameters:
    ///   - dbValue: The decibel value to weight
    ///   - freq: The frequency position of the value
    /// - Returns: The A-weighted decibel value
    private func aWeightedValue(dbValue: Float, freq: Float) -> Float {
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
    
    /// Converts a whole spectrum of normalized frequency buckets to decibels, applying A-weighting if useAWeighting is true
    ///
    /// - Parameter data: The spectrum to convert. It will be converted in place.
    private func applyDbConversion(_ data: inout [Float]) {
        var frequency: Float = 0
        let df: Float = Float(44100) / Float(fftSize * 2)
        for i in 0..<data.count {
            data[i] = convertToDB(data[i])
            
            if useAWeighting {
                data[i] = aWeightedValue(dbValue: data[i], freq: frequency)
                frequency += df
            }
        }
    }
    
    /// Applys a Hanning-window to a spectrum
    ///
    /// - Parameter data: The spectrum to be windowed. It will be windowed in place.
    private func applyHanningWindow(_ data: inout [Float]) {
        for i in 0..<data.count {
            data[i] = data[i] * 0.5 * (1.0 - cos(2.0 * Float.pi * Float(i) / Float(data.count)))
        }
    }
    
    func getVisualSpectrum() -> [Float] {
        var visualSpectrum = normalizeFFT(gist.melFrequencySpectrum())
        
        for i in 0..<visualSpectrum.count {
            visualSpectrum[i] = convertToDB(visualSpectrum[i]) - 40 * Float(visualSpectrum.count - i / 3) / Float(visualSpectrum.count)
        }
        
        return visualSpectrum
    }
}

protocol BufferProcessorDelegate: class {
    func bufferProcessorFinishedProcessing(_ sender: BufferProcessor)
}
