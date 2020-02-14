//
//  FourierTransform.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/20/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class AudioAnalyzer {
	private var fftSetup = LuxampFFTSetup()
	private var outMagnitudes: [Float]
	
	init(bufferSize: Int) {
		let log2n = Int32(roundf(log2(Float(bufferSize))))
		outMagnitudes = [Float](repeating: 0.0, count: bufferSize/2)
		initialize_fft_setup(&fftSetup, Int32(bufferSize), log2n)
	}
	
	deinit {
		destroy_fft_setup(fftSetup)
	}
	
	/// Computes the FFT and amplitude of the given buffer
	func analyze(buffer: [Float]) -> AnalyzedAudio {
		var amplitude: Float = 0.0
		
		perform_fft(&fftSetup, UnsafePointer<Float>(buffer), &outMagnitudes)
		amplitude = root_mean_square(&fftSetup, UnsafePointer<Float>(buffer))
		
		return AnalyzedAudio(outMagnitudes, amplitude: amplitude)
	}
}


class AnalyzedAudio {
	private let frequencyBins: [Float]
	private let amplitude: Float
	
	fileprivate init(_ frequencyBins: [Float], amplitude: Float) {
		self.frequencyBins = frequencyBins
		self.amplitude = amplitude
	}
	
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
