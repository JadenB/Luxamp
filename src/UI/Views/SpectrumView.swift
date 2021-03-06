//
//  SpectrumView.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class SpectrumView: NSView {
    
    @IBInspectable var color: NSColor = NSColor.black
    @IBInspectable var backgroundColor: NSColor = NSColor.white
    
    @IBInspectable var max: Float = 1.0
    @IBInspectable var min: Float = 0.0
    
    private var spectrumMask = CAShapeLayer()
    
	private var filters = [BiasedIIRFilter](count: 2, elementCreator: BiasedIIRFilter(initialValue: 0.0))
    var spectrumSize = 2
    
    override func makeBackingLayer() -> CALayer {
        let bgGradient = CAGradientLayer()
        bgGradient.colors = [
            CGColor(gray: 0.1, alpha: 1.0),
            CGColor(gray: 0.05, alpha: 1.0)
        ]
        bgGradient.startPoint = .zero
        bgGradient.endPoint = CGPoint(x: 0.0, y: 1.0)
        bgGradient.frame = bounds
        bgGradient.needsDisplayOnBoundsChange = true
        
        let rainbowGradient = CAGradientLayer()
        rainbowGradient.colors = [
            NSColor.red.cgColor,
            NSColor.orange.cgColor,
            NSColor.yellow.cgColor,
            NSColor.green.cgColor,
            NSColor.cyan.cgColor,
            NSColor.blue.cgColor,
            NSColor.systemPink.cgColor
        ]
        rainbowGradient.startPoint = .zero
        rainbowGradient.endPoint = CGPoint(x: 1.0, y: 0.0)
        rainbowGradient.frame = bounds
        rainbowGradient.shouldRasterize = true
        rainbowGradient.needsDisplayOnBoundsChange = true
        rainbowGradient.mask = spectrumMask
        bgGradient.addSublayer(rainbowGradient)
        
        return bgGradient
    }
    
    override var isOpaque: Bool {
        return true
    }
    
    override var wantsLayer: Bool {
        get { return true }
        set { return }
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func prepareForInterfaceBuilder() {
        var newSpectrum = [Float](repeating: 0.0, count: 8)
        
        for i in 0..<newSpectrum.count {
            newSpectrum[i] = min + (max - min) * Float(arc4random()) / Float(UINT32_MAX)
        }
        
        setSpectrum(newSpectrum)
    }
    
    func setSpectrum(_ newSpectrum: [Float]) {
        if newSpectrum.count != spectrumSize {
			filters.removeAll()
			filters = (0..<newSpectrum.count).map { _ in
				let newFilter = BiasedIIRFilter(initialValue: 0.0)
				newFilter.upwardsAlpha = 0.4
				newFilter.downwardsAlpha = 0.4
				return newFilter
			}

            spectrumSize = newSpectrum.count
        }
        
		let filteredSpectrum = (0..<newSpectrum.count).map { i -> Float in
			let filteredValue = filters[i].filter(nextValue: newSpectrum[i])
			return remapValueToUnit(filteredValue, min: min, max: max)
		}
        
        let curvePoints = layoutCurvePoints(fromSpectrum: filteredSpectrum)
        let path = CGMutablePath()
        
        // Smooth bars spectrum
        let curve = QuadraticCurve(withPoints: curvePoints)
        
        let barCount = 32
        let space: CGFloat = 4
        
        let dx: CGFloat = (bounds.width - space * 2) / CGFloat(barCount)
        var x = space + dx / 2
        for _ in 0..<barCount {
            let h = curve.interpolate(atPosition: x / bounds.width).y
            
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: h))
            x += dx
        }
        
        let stroked = path.copy(strokingWithWidth: dx - space * 2, lineCap: .butt, lineJoin: .bevel, miterLimit: 0.0)
        spectrumMask.path = stroked
        needsDisplay = true
    }
    
    func clear() {
		filters.forEach { $0.reset(toValue: min) }
        setSpectrum( [Float](repeating: min, count: spectrumSize) )
    }
    
    private func layoutCurvePoints(fromSpectrum spectrum: [Float]) -> [CGPoint] {
        var points = [CGPoint]()
        points.reserveCapacity(spectrum.count + 2)
        
        var x: CGFloat = 0.0
        let dx = bounds.width / CGFloat(spectrum.count + 1)
        let h = bounds.height
        
        points.append(.zero)
        x += dx
        for bar in spectrum {
            points.append(CGPoint(x: x, y: CGFloat(bar) * h))
            x += dx
        }
        points.append(CGPoint(x: bounds.width, y: 0))
        
        return points
    }
}


class QuadraticCurve {
    
    private var points: [CGPoint]
    private var midPoints: [CGPoint]
    
    init(withPoints p: [CGPoint]) {
        if p.count < 2 {
            fatalError("Curve must have at least 2 points")
        }
        
        points = p
        midPoints = [CGPoint]()
        midPoints.reserveCapacity(p.count + 2)
        
        midPoints.append(.zero)
        
        for i in 0..<points.count - 1 {
            let cur = points[i]
            let next = points[i + 1]
            midPoints.append( CGPoint(x: (cur.x + next.x) / 2, y: (cur.y + next.y) / 2) )
        }
        
        let last = points.count - 1
        let endXDiff = points[last].x - midPoints[last].x
        let endYDiff = points[last].y - midPoints[last].y
        midPoints.append( CGPoint(x: points[last].x - endXDiff, y: points[last].y - endYDiff) )
        
        let startXDiff = midPoints[1].x - points[0].x
        let startYDiff = midPoints[1].y - points[0].y
        midPoints[0] = CGPoint(x: points[0].x - startXDiff, y: points[0].y - startYDiff)
    }
    
    func interpolate(atPosition pos: CGFloat) -> CGPoint {
        if pos > 1.0 || pos < 0.0 {
            print("invalid interpolation position \(pos)")
            return .zero
        }
        
        var aPos = pos * CGFloat(points.count) / CGFloat(midPoints.count)
        aPos += (1.0 - CGFloat(points.count) / CGFloat(midPoints.count)) / 2
        
        let pIndex = Int(aPos * CGFloat(points.count))
        let mps = midPointsSurrounding(index: pIndex)
        let p0 = mps.left
        let p1 = points[pIndex] // control point
        let p2 = mps.right
        
        let t = aPos * CGFloat(points.count) - CGFloat(pIndex)
        let ix = (1 - t) * (1 - t) * p0.x + 2 * (1 - t) * t * p1.x + t * t * p2.x
        let iy = (1 - t) * (1 - t) * p0.y + 2 * (1 - t) * t * p1.y + t * t * p2.y
        
        return CGPoint(x: ix, y: iy)
    }
    
    private func midPointsSurrounding(index: Int) -> (left: CGPoint, right: CGPoint) {
        return (midPoints[index], midPoints[index + 1])
    }
    
}
