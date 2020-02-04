//
//  SignalFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/3/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


protocol SignalFilter {
	init(initialValue: Float)
	func filter(nextValue: Float) -> Float
	func reset(toValue value: Float)
}
