//
//  SmoothingView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/23/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class SmoothingView: NSView {
    
    let smoothLayer = SmoothingGraphLayer()
    @IBInspectable var smoothing: CGFloat = 0.0 {
        didSet { smoothLayer.smoothing = smoothing }
    }
    
    var color: NSColor = .white {
        didSet { smoothLayer.color = color.cgColor }
    }
    
    var backgroundColor: NSColor = .black {
        didSet { smoothLayer.backgroundColor = backgroundColor.cgColor }
    }
    
    var lineWidth: Float {
        get { return Float(smoothLayer.lineWidth) }
        set { smoothLayer.lineWidth = CGFloat(newValue) }
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override var wantsLayer: Bool {
        get { return true }
        set { return }
    }
    
    override func makeBackingLayer() -> CALayer {
        smoothLayer.needsDisplayOnBoundsChange = true
        smoothLayer.frame = bounds
        return smoothLayer
    }
    
}

class SmoothingGraphLayer: CALayer {
    let regSine: [CGFloat] = [
        0.50, 0.53, 0.56, 0.58, 0.61, 0.63, 0.65, 0.67, 0.69, 0.70,
        0.71, 0.72, 0.72, 0.72, 0.72, 0.71, 0.70, 0.69, 0.67, 0.65,
        0.63, 0.61, 0.58, 0.56, 0.53, 0.50, 0.47, 0.44, 0.42, 0.39,
        0.37, 0.35, 0.33, 0.31, 0.30, 0.29, 0.28, 0.28, 0.28, 0.28,
        0.29, 0.30, 0.31, 0.33, 0.35, 0.37, 0.39, 0.42, 0.44, 0.47 ]
    let noisySine: [CGFloat] = [
        0.50, 0.52, 0.55, 0.55, 0.62, 0.54, 0.65, 0.72, 0.52, 0.68,
        0.74, 0.56, 0.77, 0.73, 0.76, 0.61, 0.52, 0.59, 0.51, 0.55,
        0.62, 0.57, 0.56, 0.53, 0.52, 0.50, 0.49, 0.49, 0.45, 0.37,
        0.33, 0.31, 0.31, 0.49, 0.43, 0.39, 0.25, 0.41, 0.37, 0.50,
        0.44, 0.27, 0.28, 0.49, 0.40, 0.33, 0.48, 0.41, 0.49, 0.49 ]
    
    var smoothing: CGFloat = 0.0 {
        didSet { setNeedsDisplay() }
    }
    
    var color: CGColor = CGColor.white {
        didSet { setNeedsDisplay() }
    }
    
    var lineWidth: CGFloat = 3.0
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    private func commonInit() {
        backgroundColor = NSColor.black.cgColor
    }
    
    override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        let width = bounds.width
        let height = bounds.height
        
        ctx.move(to: NSPoint(x: 0, y: regSine[0] * height))
        
        let size = regSine.count
        let dx = width / CGFloat(size)
        var x = dx
        for i in 1..<size {
            let smoothedVal = smoothing * regSine[i] + (1 - smoothing) * noisySine[i]
            ctx.addLine(to: CGPoint(x: x, y: height * smoothedVal))
            x += dx
        }
        
        ctx.saveGState()
        ctx.setStrokeColor(color)
        ctx.setLineWidth(lineWidth)
        ctx.strokePath()
        ctx.restoreGState()
    }
}
