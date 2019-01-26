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
    
    var spectrumLayer = SpectrumLayer()
    var spectrum: [Float] = [] {
        didSet {
            spectrumLayer.spectrum = spectrum.map { CGFloat(remapValueToBounds($0, min: min, max: max)) }
            needsDisplay = true
        }
    }
    
    convenience init(min: Float, max: Float) {
        self.init()
        self.min = min
        self.max = max
    }
    
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
        
        for i in 0..<spectrum.count {
            newSpectrum[i] = min + (max - min) * Float(arc4random()) / Float(UINT32_MAX)
        }
        
        spectrumLayer.spectrum = newSpectrum.map { CGFloat(remapValueToBounds($0, min: min, max: max)) }
        needsDisplay = true
    }
    
}

class SpectrumLayer: CALayer {
    var gradientLayer = CAGradientLayer()
    var spectrumMask = CAShapeLayer()
    
    var spectrum: [CGFloat] = [1, 1] {
        didSet {
            if spectrum.count <= 1 { spectrum = [1, 1] }
            let path = CGMutablePath()
            path.move(to: .zero)
            
            var x: CGFloat = 0.0
            let dx: CGFloat = bounds.width / CGFloat(spectrum.count - 1)
            let h = bounds.height
            for i in stride(from: 0, to: spectrum.count - 3, by: 3) {
                let control1 = CGPoint(x: x, y: spectrum[i] * h)
                x += dx
                let control2 = CGPoint(x: x, y: spectrum[i + 1] * h)
                x += dx
                path.addCurve(to: CGPoint(x: x, y: spectrum[i + 2] * h), control1: control1, control2: control2)
                x += dx
            }
            path.addLine(to: CGPoint(x: bounds.width, y: 0))
            path.closeSubpath()
            
            spectrumMask.path = path
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
}
