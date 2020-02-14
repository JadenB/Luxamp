//
//  SavitzkyGolayFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/3/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

/*
Read more: https://gregstanleyandassociates.com/whitepapers/FaultDiagnosis/Filtering/LeastSquares-Filter/leastsquares-filter.htm
*/

import Foundation


class SavitzkyGolayFilter: SignalFilter {
	enum Order: Int {
		case three = 3
		case four = 4
		case six = 6
		case seven = 7
		case nine = 9
	}
	
	var order: Order = .four {
		didSet {
			let orderDiff = order.rawValue - oldValue.rawValue
			if orderDiff > 0 {
				_history.reserveCapacity(order.rawValue)
				_history.append(contentsOf: [Float](repeating: _history[_history.count-1], count: orderDiff))
			} else {
				_history.removeLast(-orderDiff)
			}
		}
	}
	
	/// The N most recent input signal samples with the most recent at the beginning, where N = order
	private var _history: [Float]
	
	required init(initialValue: Float) {
		_history = [Float](repeating: initialValue, count: order.rawValue)
	}
	
	init(initialValue: Float, filterOrder: Order) {
		_history = [Float](repeating: initialValue, count: filterOrder.rawValue)
		order = filterOrder
	}
	
	func reset(toValue value: Float) {
		_history = [Float](repeating: value, count: order.rawValue)
	}
	
	func filter(nextValue: Float) -> Float {
		_history.removeLast()
		_history.insert(nextValue, at: 0)
		
		var newVal: Float = 0.0
		
		switch order {
		case .three:
			newVal = 0.83333 * _history[0] + 0.33333 * _history[1] - 0.16667 * _history[2]
		case .four:
			newVal = 0.7 * _history[0] + 0.4 * _history[1] + 0.1 * _history[2] - 0.2 * _history[3]
		case .six:
			newVal = 0.52381 * _history[0] + 0.38095 * _history[1] + 0.2381 * _history[2] + 0.09524 * _history[3] - 0.04762 * _history[4] - 0.19048 * _history[5]
		case .seven:
			newVal = 0.46429 * _history[0] + 0.35714 * _history[1] + 0.25 * _history[2] + 0.14286 * _history[3] + 0.03571 * _history[4] - 0.07143 * _history[5] - 0.17857 * _history[6]
		case .nine:
			newVal = 0.37778 * _history[0] + 0.31111 * _history[1] + 0.24444 * _history[2] + 0.17778 * _history[3] + 0.11111 * _history[4] + 0.04444 * _history[5] - 0.02222 * _history[6]  - 0.08889 * _history[7] - 0.11156 * _history[8]
		}
		
		return newVal
	}
	
	private func resizeHistory(newSize: Int) {
		
	}
}
