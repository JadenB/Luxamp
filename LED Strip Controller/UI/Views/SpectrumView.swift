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
        get {
            return true
        }
    }
    
    override var wantsLayer: Bool {
        get { return true }
        set { return }
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func prepareForInterfaceBuilder() {
        var newSpectrum = [Float](repeating: 0.0, count: 256)
        
        for i in 0..<spectrumSize {
            newSpectrum[i] = min + (max - min) * Float(arc4random()) / Float(UINT32_MAX)
        }
        
        spectrumLayer.spectrum = newSpectrum.map { CGFloat(remapValueToBounds($0, min: min, max: max)) }
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
            var filteredVal = remapValueToBounds(newSpectrum[i], min: min, max: max)
            filteredVal = filter.applyFilter(toValue: filteredVal, atIndex: i)
            filteredSpectrum[i] = CGFloat(filteredVal)
        }
        
        spectrumLayer.spectrum = filteredSpectrum
        needsDisplay = true
    }
}

class SpectrumLayer: CALayer {
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
        let color7 = NSColor.purple
        gradientLayer.colors = [color1.cgColor, color2.cgColor, color3.cgColor, color4.cgColor, color5.cgColor, color6.cgColor, color7.cgColor]
        
        gradientLayer.mask = spectrumMask
        gradientLayer.startPoint = .zero
        gradientLayer.endPoint = CGPoint(x: 1.0, y: 0.0)
        gradientLayer.shouldRasterize = true
        addSublayer(gradientLayer)
        
        spectrumMask.drawsAsynchronously = true
    }
    
    private func updateMask() {
        if spectrum.count <= 1 { spectrum = [1, 1] }
        let path = CGMutablePath()
        path.move(to: .zero)
        
        let points = layoutPoints()
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
