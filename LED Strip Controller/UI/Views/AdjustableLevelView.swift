//
//  AdjustableLevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 3/13/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class AdjustableLevelView: RangeControl {
    
	var level: Float = 0.0 {
		didSet {
			let h = remapValueToBounds(level, inputMin: min, inputMax: max, outputMin: 0.0, outputMax: Float(bounds.height))
			let levelRect = NSRect(x: 0.0, y: 0.0, width: bounds.width, height: CGFloat(h))
			levelLayer.path = CGPath(rect: levelRect, transform: nil)
		}
	}
	
	private var levelLayer = CAShapeLayer()
	private var sliderLayer = CAShapeLayer()
	
	override var wantsUpdateLayer: Bool {
		return true
	}
	
	override var isOpaque: Bool {
		return true
	}
	
	override func makeBackingLayer() -> CALayer {
		let bgGradient = CAGradientLayer()
		bgGradient.needsDisplayOnBoundsChange = true
		bgGradient.frame = bounds
		bgGradient.colors = [
			CGColor(gray: 0.1, alpha: 1.0),
			CGColor(gray: 0.05, alpha: 1.0)
		]
		bgGradient.startPoint = .zero
		bgGradient.endPoint = CGPoint(x: 0.0, y: 1.0)
		
		levelLayer.fillColor = NSColor.red.cgColor
		bgGradient.addSublayer(levelLayer)
		
		sliderLayer.fillColor = .white
		sliderLayer.shadowOpacity = 0.5
		bgGradient.addSublayer(sliderLayer)
		
		return bgGradient
	}
	
	override func didUpdateSliderBounds() {
		let path = CGMutablePath()
		path.addRect(upperSliderBounds)
		path.addRect(lowerSliderBounds)
		sliderLayer.path = path
	}
	
	func clear() {
		level = 0.0
	}
    
}
