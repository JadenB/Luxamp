//
//  LevelIndicatorArcLayer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/18/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class LevelIndicatorArcLayer: CALayer {
    var startAngle: CGFloat = 0.0
    var endAngle: CGFloat = 360.0
    var levelWidth: CGFloat = 2.0
    
    var level: Float = 0.5 {
        didSet {
            setNeedsDisplay()
        }
    }
    var levelColor: NSColor = .white
    
    override init() {
        super.init()
        needsDisplayOnBoundsChange = true
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func draw(in ctx: CGContext) {
        print("drew sublayer")
        let lineAngle: CGFloat = startAngle + CGFloat(level) * (endAngle - startAngle)
        let r = bounds.size.width / 2
        
        ctx.setStrokeColor(levelColor.cgColor)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        ctx.move(to: center)
        
        ctx.saveGState()
        ctx.addLine(to: CGPoint(x: center.x + r * cos(lineAngle * CGFloat.pi / 180), y: center.y + r * sin(lineAngle * CGFloat.pi / 180)))
        ctx.strokePath()
        ctx.restoreGState()
    }
    
    
}
