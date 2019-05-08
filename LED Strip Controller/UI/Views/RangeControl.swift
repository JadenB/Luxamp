//
//  RangeControl.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 3/29/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class RangeControl: NSControl {
	
	weak var delegate: RangeControlDelegate?
	
	var sliderThickness: CGFloat = 5.0
	var max: Float = 1.0
	var min: Float = 0.0
	var minDistance: Float = 0.10
	
	var upperValue: Float = 1.0 {
		didSet {
			let rectY = CGFloat(remapValueToBounds(upperValue, inputMin: min, inputMax: max, outputMin: 0.0, outputMax: Float(effHeight)))
			upperSliderBounds = NSRect(x: 0.0, y: rectY, width: bounds.width, height: sliderThickness)
			window?.invalidateCursorRects(for: self)
			didUpdateSliderBounds()
		}
	}
	
	var lowerValue: Float = 0.0 {
		didSet {
			let rectY = CGFloat(remapValueToBounds(lowerValue, inputMin: min, inputMax: max, outputMin: 0.0, outputMax: Float(effHeight)))
			lowerSliderBounds = NSRect(x: 0.0, y: rectY, width: bounds.width, height: sliderThickness)
			window?.invalidateCursorRects(for: self)
			didUpdateSliderBounds()
		}
	}
	
	var upperSliderBounds: NSRect = .zero
	var lowerSliderBounds: NSRect = .zero
	
	private var tracking: TrackingStatus = .None
	private var baseLoc: NSPoint = .zero
	private var baseRect: NSRect = .zero
	private var effHeight: CGFloat {
		return bounds.height - sliderThickness
	}
	
	override var isEnabled: Bool {
		didSet {
			if isEnabled {
				window?.invalidateCursorRects(for: self)
			} else {
				discardCursorRects()
			}
		}
	}
	
	override init(frame frameRect: NSRect) {
		super.init(frame: frameRect)
		commonInit()
	}
	
	required init?(coder: NSCoder) {
		super.init(coder: coder)
		commonInit()
	}
	
	private func commonInit() {
		isEnabled = true
	}
	
	override func mouseDown(with event: NSEvent) {
		if !isEnabled {
			return
		}
		
		if event.clickCount == 2 {
			upperValue = max
			lowerValue = min
			delegate?.rangeControlSlidersChanged(self)
			return
		}
		
		let loc = convert(event.locationInWindow, from: nil)
		if upperSliderBounds.contains(loc) {
			tracking = .Upper
			baseRect = upperSliderBounds
		} else if lowerSliderBounds.contains(loc) {
			tracking = .Lower
			baseRect = lowerSliderBounds
		} else {
			return
		}
		
		baseLoc = loc
		window?.disableCursorRects()
		NSCursor.resizeUpDown.set()
	}
	
	override func mouseDragged(with event: NSEvent) {
		if tracking == .None {
			return
		}
		
		let loc = convert(event.locationInWindow, from: nil)
		let newLocY = baseRect.minY + loc.y - baseLoc.y
		let newVal = remapValueToBounds(Float(newLocY), inputMin: 0.0, inputMax: Float(effHeight), outputMin: min, outputMax: max)
		
		if tracking == .Upper {
			if newVal < lowerValue + minDistance {
				upperValue = lowerValue + minDistance
			} else {
				upperValue = newVal
			}
		} else {
			if newVal > upperValue - minDistance {
				lowerValue = upperValue - minDistance
			} else {
				lowerValue = newVal
			}
		}
		
		if isContinuous {
			delegate?.rangeControlSlidersChanged(self)
		}
		
		needsDisplay = true
	}
	
	override func mouseUp(with event: NSEvent) {
		if tracking == .None {
			return
		}
		
		tracking = .None
		
		window?.invalidateCursorRects(for: self)
		window?.enableCursorRects()
		
		if !isContinuous {
			delegate?.rangeControlSlidersChanged(self)
		}
	}
	
	override func resetCursorRects() {
		if isEnabled {
			addCursorRect(upperSliderBounds, cursor: .resizeUpDown)
			addCursorRect(lowerSliderBounds, cursor: .resizeUpDown)
		}
	}
	
	func didUpdateSliderBounds() {}
	
	func resizePreservingSliders(newMin: Float, newMax: Float) {
		upperValue = remapValueToBounds(upperValue, inputMin: min, inputMax: max, outputMin: newMin, outputMax: newMax)
		lowerValue = remapValueToBounds(lowerValue, inputMin: min, inputMax: max, outputMin: newMin, outputMax: newMax)
		minDistance = remapValueToBounds(minDistance, inputMin: min, inputMax: max, outputMin: newMin, outputMax: newMax)
		min = newMin
		max = newMax
	}
	
	private enum TrackingStatus {
		case None
		case Upper
		case Lower
	}
}

protocol RangeControlDelegate: class {
	func rangeControlSlidersChanged(_ sender: RangeControl)
}
