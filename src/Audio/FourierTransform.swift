//
//  FourierTransform.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/20/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class FourierTransform {
	private var fftSetup = LuxampFFTSetup()
	private var outMagnitude: [Float]
	
	init(bufferSize: Int) {
		let log2n = Int32(roundf(log2(Float(bufferSize))))
		outMagnitude = [Float](repeating: 0.0, count: bufferSize/2)
		initialize_fft_setup(&fftSetup, Int32(bufferSize), log2n)
	}
	
	deinit {
		destroy_fft_setup(fftSetup)
	}
	
	func perform(buffer: [Float]) -> [Float] {
		perform_fft(&fftSetup, UnsafePointer<Float>(buffer), &outMagnitude)
		return outMagnitude
	}
}
