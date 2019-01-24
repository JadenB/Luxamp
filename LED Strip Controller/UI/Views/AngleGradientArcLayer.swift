//
//  AngleGradientArcLayer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/15/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class AngleGradientArcLayer: AngleGradientLayer {
    
    // MARK: - Variables
    
    private var levelLayer = AngleLineLayer()
    private var arcMask = CAShapeLayer()
    
    var middleSpace: CGFloat = 12.0
    var arcWidth: CGFloat = 1.0
    var arcStartAngle: CGFloat = 0.0 {
        didSet {
            updateLocations()
            setupMask()
        }
    }
    
    var arcEndAngle: CGFloat = 360.0 {
        didSet {
            updateLocations()
            setupMask()
        }
    }
    
    var levelWidth: CGFloat {
        get { return levelLayer.lineWidth }
        set { levelLayer.lineWidth = newValue }
    }
    
    var levelColor: NSColor {
        get { return levelLayer.levelColor }
        set { levelLayer.levelColor = newValue }
    }
    
    var level: Float = 0.0 {
        didSet {
            levelLayer.lineStartOffset = CGPoint(x: (invert ? -middleSpace : middleSpace) * CGFloat(level), y: 0.0)
            levelLayer.angle = arcStartAngle + CGFloat(invert ? 1.0 - level : level) * (arcEndAngle - arcStartAngle)
        }
    }
    
    var gradient: NSGradient! {
        didSet {
            let colorCount = gradient.numberOfColorStops
            var newColors = [CGColor]()
            newColors.reserveCapacity(colorCount)
            for i in 0..<colorCount {
                newColors.append( gradient.interpolatedColor(atLocation: CGFloat(i) * 1 / (CGFloat(colorCount) - 1)).cgColor )
            }
            
            if !invert {
                newColors.reverse()
            }
            
            colors = newColors
            updateLocations()
            setNeedsDisplay()
        }
    }
    
    private var prevInvert = false
    var invert: Bool = false {
        didSet {
            if prevInvert != invert {
                colors.reverse()
                prevInvert = invert
                setNeedsDisplay()
            }
        }
    }
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        shouldRasterize = true
        colors = [NSColor.black.cgColor, NSColor.white.cgColor]
        gradient = NSGradient(starting: .black, ending: .white)
        levelLayer.mask = arcMask
        addSublayer(levelLayer)
    }
    
    // MARK: - Overrides
    
    override func draw(in ctx: CGContext) {
        setupMask()
        ctx.saveGState()
        ctx.addPath(arcMask.path ?? CGPath(rect: bounds, transform: nil))
        ctx.clip()
        super.draw(in: ctx)
        ctx.restoreGState()
        
        ctx.saveGState()
        ctx.setBlendMode(.clear)
        ctx.setFillColor(CGColor.white)
        ctx.fill(CGRect(x: bounds.midX - middleSpace, y: 0, width: middleSpace * 2, height: bounds.height))
        ctx.restoreGState()
    }
    
    override func contains(_ p: CGPoint) -> Bool {
        return arcMask.path?.contains(p) ?? false
    }
    
    override func layoutSublayers() {
        levelLayer.frame = bounds
        arcMask.frame = bounds
    }
    
    // MARK: - Utility Functions
    
    private func updateLocations() {
        let colorCount = colors.count
        
        var locs = [NSNumber]()
        locs.reserveCapacity(colorCount)
        
        let angleDiff = Double( abs(arcEndAngle - arcStartAngle) )
        let dl = angleDiff / Double(colorCount - 1)
        var l = 360.0 - angleDiff
        let scalingFactor: Double = 1.0 / 360.0
        for _ in 0..<colorCount {
            locs.append(NSNumber(floatLiteral: l * scalingFactor))
            l += dl
        }
        
        locations = locs
        startAngle = arcStartAngle * (2 * CGFloat.pi / 360.0)
    }
    
    private func setupMask() {
        arcMask.frame = bounds
        let arcPath = NSBezierPath()
        let center = NSPoint(x: bounds.midX, y: bounds.midY)
        arcPath.appendArc(withCenter: center, radius: (bounds.size.width - arcWidth) / 2, startAngle: arcStartAngle, endAngle: arcEndAngle, clockwise: false)
        arcMask.path = arcPath.cgPath.copy(strokingWithWidth: arcWidth, lineCap: .butt, lineJoin: .bevel, miterLimit: 0)
    }
}
