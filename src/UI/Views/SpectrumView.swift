//
//  SpectrumView.swift
//  LED Strip Controller
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
    
    private var spectrumLayer = SpectrumLayer()
    
    private var filter = BiasedIIRFilter(size: 2)
    var spectrumSize = 2
    
    override func makeBackingLayer() -> CALayer {
        spectrumLayer.needsDisplayOnBoundsChange = true
        spectrumLayer.frame = bounds
        spectrumLayer.backgroundColor = NSColor.black.cgColor
        return spectrumLayer
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
        
        spectrumLayer.spectrum = newSpectrum.map { CGFloat(remapValueToUnit($0, min: min, max: max)) }
        needsDisplay = true
    }
    
    func setSpectrum(_ newSpectrum: [Float]) {
        if newSpectrum.count != spectrumSize {
            filter = BiasedIIRFilter(size: newSpectrum.count)
            filter.upwardsAlpha = 0.4
            filter.downwardsAlpha = 0.4
            spectrumSize = newSpectrum.count
        }
        
        var filteredSpectrum = [CGFloat](repeating: 0.0, count: newSpectrum.count)
        for i in 0..<filteredSpectrum.count {
            var filteredVal = remapValueToUnit(newSpectrum[i], min: min, max: max)
            filteredVal = filter.applyFilter(toValue: filteredVal, atIndex: i)
            filteredSpectrum[i] = CGFloat(filteredVal)
        }
        
        spectrumLayer.spectrum = filteredSpectrum
        needsDisplay = true
    }
    
    func clear() {
        filter.clearData()
        setSpectrum( [Float](repeating: min, count: spectrumSize) )
    }
}

class SpectrumLayer: CAGradientLayer {
    var gradientLayer = CAGradientLayer()
    var spectrumMask = CAShapeLayer()
    
    var spectrum: [CGFloat] = [1, 1] {
        didSet {
            updateMask()
        }
    }
    
    override var bounds: CGRect {
        didSet { gradientLayer.frame = bounds }
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        gradientLayer = CAGradientLayer()
        gradientLayer.needsDisplayOnBoundsChange = true
        
        let color1 = NSColor.red
        let color2 = NSColor.orange
        let color3 = NSColor.yellow
        let color4 = NSColor.green
        let color5 = NSColor.cyan
        let color6 = NSColor.blue
        let color7 = NSColor.systemPink
        gradientLayer.colors = [color1.cgColor, color2.cgColor, color3.cgColor, color4.cgColor, color5.cgColor, color6.cgColor, color7.cgColor]
        
        gradientLayer.mask = spectrumMask
        gradientLayer.startPoint = .zero
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        gradientLayer.shouldRasterize = true
        addSublayer(gradientLayer)
        
        spectrumMask.drawsAsynchronously = true
        
        colors = [
            CGColor(gray: 0.1, alpha: 1.0),
            CGColor(gray: 0.05, alpha: 1.0)
        ]
        startPoint = .zero
        endPoint = CGPoint(x: 0.0, y: 1.0)
    }
    
    private func updateMask() {
        if spectrum.count <= 1 { spectrum = [1, 1] }
        let path = CGMutablePath()
        path.move(to: .zero)
        
        let points = layoutPoints()
        
        // Smooth bars spectrum
        let curve = QuadraticCurve(withPoints: points)
        
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
        // End smooth bars spectrum
        
        // Smooth curve spectrum
        /*
        path.addLine(to: points[0])
        
        for i in 1..<points.count {
            let curPoint = points[i]
            let prevPoint = points[i - 1]
            let midPoint = CGPoint(x: (prevPoint.x + curPoint.x) / 2, y: (prevPoint.y + curPoint.y) / 2)
            path.addQuadCurve(to: midPoint, control: prevPoint)
        }
        
        path.addLine(to: CGPoint(x: bounds.width, y: 0))
        path.closeSubpath()
        spectrumMask.path = path
        */
        // End smooth curve spectrum
    }
    
    private func layoutPoints() -> [CGPoint] {
        var points = [CGPoint]()
        points.reserveCapacity(spectrum.count + 2)
        
        var x: CGFloat = 0.0
        let dx = bounds.width / CGFloat(spectrum.count + 1)
        let h = bounds.height
        
        points.append(.zero)
        x += dx
        for bar in spectrum {
            points.append(CGPoint(x: x, y: bar * h))
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
            print("invalid t")
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
