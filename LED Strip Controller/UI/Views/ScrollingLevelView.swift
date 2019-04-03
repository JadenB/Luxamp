//
//  ScrollingLevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 3/25/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class ScrollingLevelView: RangeControl {
	@IBInspectable var highLightThickness: CGFloat = 3.0
	
	private var history = CircularHistory<CGFloat>(length: 40, initialData: 0.0)
	private var scrollingMask = CAShapeLayer()
	private var strokeMask = CAShapeLayer()
	private var upperSliderLayer = CAShapeLayer()
	private var lowerSliderLayer = CAShapeLayer()
	
	override func makeBackingLayer() -> CALayer {
		let backgroundGradient = CAGradientLayer()
		backgroundGradient.needsDisplayOnBoundsChange = true
		backgroundGradient.frame = bounds
		
		backgroundGradient.colors = [
			CGColor(gray: 0.1, alpha: 1.0),
			CGColor(gray: 0.05, alpha: 1.0)
		]
		backgroundGradient.startPoint = .zero
		backgroundGradient.endPoint = CGPoint(x: 0.0, y: 1.0)
		
		let scrollingGradient = CAGradientLayer()
		scrollingGradient.colors = [
			CGColor.clear,
			NSColor.red.cgColor
		]
		scrollingGradient.startPoint = .zero
		scrollingGradient.endPoint = CGPoint(x: 1.0, y: 0.0)
		scrollingGradient.frame = bounds
		scrollingGradient.mask = scrollingMask
		scrollingMask.drawsAsynchronously = true
		
		let strokeGradientMask = CAGradientLayer()
		strokeGradientMask.colors = [
			CGColor.clear,
			CGColor.clear,
			CGColor.white
		]
		strokeGradientMask.startPoint = .zero
		strokeGradientMask.endPoint = CGPoint(x: 1.0, y: 0.0)
		strokeGradientMask.frame = bounds
		
		let strokeGradient = CAGradientLayer()
		strokeGradient.colors = [
			NSColor.green.cgColor,
			NSColor.yellow.cgColor,
			NSColor.red.cgColor
		]
		strokeGradient.startPoint = .zero
		strokeGradient.endPoint = CGPoint(x: 0.0, y: 1.0)
		strokeGradient.frame = bounds
		
		let clipLayer = CALayer()
		strokeGradient.mask = strokeGradientMask
		strokeGradient.shouldRasterize = true
		clipLayer.addSublayer(strokeGradient)
		clipLayer.mask = strokeMask
		
		upperSliderLayer.frame = bounds
		upperSliderLayer.fillColor = .white
		upperSliderLayer.shadowOpacity = 0.5
		lowerSliderLayer.frame = bounds
		lowerSliderLayer.fillColor = .white
		lowerSliderLayer.shadowOpacity = 0.5
		
		backgroundGradient.addSublayer(scrollingGradient)
		backgroundGradient.addSublayer(clipLayer)
		backgroundGradient.addSublayer(upperSliderLayer)
		backgroundGradient.addSublayer(lowerSliderLayer)
		return backgroundGradient
	}
	
	override var wantsUpdateLayer: Bool {
		return true
	}
	
	override var wantsLayer: Bool {
		get { return true }
		set { return }
	}
	
	override var isOpaque: Bool {
		return true
	}
	
	func pushLevel(_ level: Float) {
		history.push(CGFloat(level))
		updateMasks()
	}
	
	private func updateMasks() {
		let maskPath = CGMutablePath()
		let strokePath = CGMutablePath()
		
		let h = bounds.height
		let dx = bounds.width / CGFloat(history.length - 1)
		let halfThick = highLightThickness / 2
		var x: CGFloat = 0.0
		
		maskPath.move(to: .zero)
		strokePath.move(to: .zero)
		for i in 0..<history.length {
			maskPath.addLine(to: CGPoint(x: x, y: history[i] * h))
			strokePath.addLine(to: CGPoint(x: x, y: history[i] * h - halfThick))
			x += dx
		}
		strokeMask.path = strokePath.copy(strokingWithWidth: highLightThickness, lineCap: .butt, lineJoin: .miter, miterLimit: 0.0)
		maskPath.addLine(to: CGPoint(x: bounds.width, y: 0.0))
		
		maskPath.closeSubpath()
		scrollingMask.path = maskPath
	}
	
	override func didUpdateSliderBounds() {
		upperSliderLayer.path = CGPath(rect: upperSliderBounds, transform: nil)
		lowerSliderLayer.path = CGPath(rect: lowerSliderBounds, transform: nil)
	}
	
	override func prepareForInterfaceBuilder() {
		history = CircularHistory<CGFloat>(length: 2, initialData: 0.5)
		updateMasks()
	}
}

class CircularHistory<T> {
	let length: Int
	private var historyData: [T]
	private var start: Int
	private let last: Int
	
	init(length: Int, initialData: T) {
		historyData = [T](repeating: initialData, count: length)
		self.length = length
		start = 0
		last = length - 1
	}
	
	func push(_ item: T) {
		historyData[start] = item
		start = (start == last) ? 0 : start + 1
	}
	
	func getAll() -> [T] {
		var result = [T]()
		result.reserveCapacity(length)
		for _ in 0..<length {
			result.append(historyData[start])
			start = (start == last) ? 0 : start + 1
		}
		return result
	}
	
	subscript(index: Int) -> T {
		get {
			return historyData[(start + index) % length]
		}
		set {
			historyData[(start + index) % length] = newValue
		}
	}
}
