//
//  AudioMapper.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/20/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class AudioMapper {
	private let fft: FourierTransform
	private var frequencyBins = [Float]()
	
	init(bufferSize: Int) {
		fft = FourierTransform(bufferSize: bufferSize)
	}
	
	func process(buffer: [Float]) {
		frequencyBins = fft.perform(buffer: buffer)
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
        for i in range {
            sum += frequencyBins[i]
        }
        
        if falloff > 0 {
            
            let df: Float = 1.0 / (Float(falloff) + 1)
            var fallOffFactor = df * (Float(falloff) + 1)
            
            for i in 1...falloff {
                fallOffFactor -= df
                if range.lowerBound - i >= 0 {
                    sum += frequencyBins[range.lowerBound - i] * fallOffFactor
                    denom += fallOffFactor
                }
                if range.upperBound + i < frequencyBins.count {
                    sum += frequencyBins[range.upperBound + i] * fallOffFactor
                    denom += fallOffFactor
                }
            }
            
        }
        return sum / denom
    } // averageMagOfRange
}
