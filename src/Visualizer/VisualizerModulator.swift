//
//  VisualizerModulator.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/19/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class VisualizerModulator {
	func valueAtLocation(_ location: Double) -> Double {
		return 0.0
	}
	
	class func sine() -> VisualizerModulator {
		return SineModulator()
	}
	
	class func linear() -> VisualizerModulator {
		return LinearModulator()
	}
	
	class func constant(_ value: Double) -> VisualizerModulator {
		return ConstantModulator(constant: value)
	}
}


fileprivate class SineModulator: VisualizerModulator {
	override func valueAtLocation(_ location: Double) -> Double {
		if location > 1.0 || location < 0.0 {
			return 0.5
		}
		
		return 0.5 + sin(2*Double.pi*location) / 2
	}
}


fileprivate class LinearModulator: VisualizerModulator {
	override func valueAtLocation(_ location: Double) -> Double {
		if location > 1.0 {
			return 1.0
		} else if location < 0.0 {
			return 0.0
		}
		
		return location
	}
}


fileprivate class ConstantModulator: VisualizerModulator {
	let constant: Double
	
	init(constant: Double) {
		if constant > 1.0 {
			self.constant = 1.0
		} else if constant < 0.0 {
			self.constant = 0.0
		} else {
			self.constant = constant
		}
	}
	
	override func valueAtLocation(_ location: Double) -> Double {
		return constant
	}
}
