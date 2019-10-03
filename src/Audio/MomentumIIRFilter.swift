//
//  MomentumIIRFilter.swift
//  Luxamp
//
//  Created by Jaden Bernal on 5/6/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Foundation

class MomentumIIRFilter {
	
	var strength: Float = 0.5
	
	private var lastVal: Float
	private var momentum: Float = 0.0
	
	init(initialData: Float) {
		lastVal = initialData
	}
	
	func applyFilter(_ data: Float) -> Float {
		
		return 0.0
	}
}
