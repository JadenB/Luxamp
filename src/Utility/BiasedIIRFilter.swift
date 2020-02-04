//
//  BiasedIIRFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/22/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

/// Applies a different alpha to an IIR Filter for increasing and decreasing values
class BiasedIIRFilter: SignalFilter {
    var upwardsAlpha: Float = 0.5
	var downwardsAlpha: Float = 0.5
    
    private var _lastValue: Float
	
	required init(initialValue: Float) {
		_lastValue = initialValue
	}
	
	func filter(nextValue: Float) -> Float {
		if nextValue > _lastValue {
			let temp: Float = upwardsAlpha * _lastValue + (1-upwardsAlpha) * nextValue
			_lastValue = temp
            return temp
        } else {
			let temp: Float = downwardsAlpha * _lastValue + (1-downwardsAlpha) * nextValue
			_lastValue = temp
            return temp
        }
	}
	
	func reset(toValue value: Float) {
		_lastValue = value
	}
}
