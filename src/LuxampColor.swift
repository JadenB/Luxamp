//
//  LuxampColor.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/19/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Cocoa


struct LuxampColor {
	var red: Float
	var green: Float
	var blue: Float
	
	init(r: Float, g: Float, b: Float) {
		self.red = r
		self.green = g
		self.blue = b
	}
	
	func asNSColor() -> NSColor {
		return NSColor(red: CGFloat(self.red), green: CGFloat(self.green), blue: CGFloat(self.blue), alpha: 1.0)
	}
}


class LuxampGradient {
	var colors: [LuxampColor]
	
	init(colors: [LuxampColor]) {
		<#statements#>
	}
}


extension NSColor {
	func asLuxampColor() -> LuxampColor {
		return LuxampColor(r: Float(self.redComponent), g: Float(self.greenComponent), b: Float(self.blueComponent))
	}
}
