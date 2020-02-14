//
//  SignalFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/3/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


protocol SignalFilter {
	func filter(nextValue: Float) -> Float
	func reset(toValue value: Float)
}
