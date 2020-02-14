//
//  MultipassFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/4/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class MultipassFilter: SignalFilter {
	private var _filters: [SignalFilter]
	
	init(initialValue: Float, filters: [SignalFilter]) {
		_filters = filters
		reset(toValue: initialValue)
	}
	
	func filter(nextValue: Float) -> Float {
		var filtered = nextValue
		for f in _filters {
			filtered = f.filter(nextValue: filtered)
		}
		return filtered
	}
	
	func reset(toValue value: Float) {
		for f in _filters {
			f.reset(toValue: value)
		}
	}
}
