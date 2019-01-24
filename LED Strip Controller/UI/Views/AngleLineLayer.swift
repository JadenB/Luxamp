//
//  LevelIndicatorArcLayer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/18/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class AngleLineLayer: CALayer {
    var lineWidth: CGFloat = 2.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var angle: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var lineStartOffset = CGPoint(x: 0.0, y: 0.0)
    
    var levelColor: NSColor = .white
    
    override init() {
        super.init()
        commonInit()
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        needsDisplayOnBoundsChange = true
    }
    
    override func draw(in ctx: CGContext) {
        let r = bounds.size.width / 2
        
        ctx.setStrokeColor(levelColor.cgColor)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        ctx.move(to: center + lineStartOffset)
        
        ctx.saveGState()
        ctx.setLineWidth(lineWidth)
        ctx.addLine(to: CGPoint(x: center.x + r * cos(angle * CGFloat.pi / 180), y: center.y + r * sin(angle * CGFloat.pi / 180)))
        ctx.strokePath()
        ctx.restoreGState()
    }
    
}

extension CGPoint {
    public static func +(_ left: CGPoint, _ right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
}
