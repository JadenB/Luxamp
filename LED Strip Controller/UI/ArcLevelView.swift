//
//  ArcLevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/15/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//
/*
import Cocoa

@IBDesignable
class ArcLevelView: NSView {
    
    // MARK: - Variables
    
    private var mask = CAShapeLayer()
    private var arcGradientLayer = AngleGradientArcLayer()
    private var levelLayer = LevelIndicatorArcLayer()
    
    private var colors: [CGColor] = [NSColor.red.cgColor, NSColor.yellow.cgColor] {
        didSet {
            (layer as? AngleGradientArcLayer)?.colors = colors
        }
    }
    
    // MARK: - Initializers
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    // MARK: - Visible Attributes
    
    @IBInspectable var gradient: NSGradient! = NSGradient(starting: .black, ending: .white) {
        didSet {
            let colorCount = gradient.numberOfColorStops
            var newColors = [CGColor]()
            newColors.reserveCapacity(colorCount)
            for i in 0..<colorCount {
                newColors.append( gradient.interpolatedColor(atLocation: CGFloat(i) * 1 / (CGFloat(colorCount) - 1)).cgColor )
            }
            colors = newColors
        }
    }
    
    @IBInspectable var arcWidth: CGFloat = 6 {
        didSet {
            setupMask()
        }
    }
    
    @IBInspectable var arcStartAngle: CGFloat = 0 {
        didSet {
            updateAngles()
        }
    }
    
    @IBInspectable var arcEndAngle: CGFloat = 360 {
        didSet {
            updateAngles()
        }
    }
    
    // MARK: - Utility Functions
    
    private func setupMask() {
        mask.frame = bounds
        let arcPath = NSBezierPath()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        arcPath.appendArc(withCenter: center, radius: (bounds.size.width - arcWidth) / 2, startAngle: arcStartAngle, endAngle: arcEndAngle, clockwise: false)
        mask.path = arcPath.cgPath.copy(strokingWithWidth: arcWidth, lineCap: .butt, lineJoin: .bevel, miterLimit: 0)
    }
    
    private func updateAngles() {
        arcGradientLayer.arcStartAngle = arcStartAngle
        arcGradientLayer.arcEndAngle = arcEndAngle
        
        levelLayer.startAngle = arcStartAngle
        levelLayer.endAngle = arcEndAngle
    }
    
    // MARK: - Overrides
    
    override func makeBackingLayer() -> CALayer {
        setupMask()
        
        let l = arcGradientLayer
        l.colors = colors
        l.arcWidth = arcWidth
        l.arcMaskLayer = mask
        
        let subl = levelLayer
        subl.frame = bounds
        subl.mask = mask
        l.addSublayer(subl)
        
        updateAngles()
        return l
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: window?.contentView)
        if mask.path?.contains(p) ?? false {
            print("hit")
        } else {
            print("no hit")
        }
    }
    
    override func viewDidChangeBackingProperties() {
        layer?.contentsScale = window!.backingScaleFactor
    }
    
}

extension NSBezierPath {
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            }
        }
        
        return path
    }
}
*/
