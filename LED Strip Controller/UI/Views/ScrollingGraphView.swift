//
//  ScrollingGraphView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 2/6/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class ScrollingGraphView: NSView {
    
    private let graphLayer = GraphLayer()
    private var startIndex: Int = 0
    private var data: [CGFloat] = [0,0]
    
    @IBInspectable var pointCount: Int = 2 {
        didSet {
            startIndex = 0
            data = [CGFloat](repeating: 0.0, count: pointCount)
        }
    }

    override var isOpaque: Bool {
        return true
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override var wantsLayer: Bool {
        get { return true }
        set { return }
    }
    
    override func makeBackingLayer() -> CALayer {
        graphLayer.colors = [
            CGColor(gray: 0.10, alpha: 1.0),
            CGColor(gray: 0.15, alpha: 1.0),
            CGColor(gray: 0.10, alpha: 1.0)
        ]
        
        graphLayer.needsDisplayOnBoundsChange = true
        graphLayer.setNeedsDisplay()
        return graphLayer
    }
    
    func append(value v: Float) {
        var val = v
        if val > 1.0 { val = 1.0 }
        else if val < 0.0 { val = 0.0 }
        
        data[startIndex] = CGFloat(val)
        startIndex = (startIndex + 1) % pointCount
        
        var graphData = [CGFloat]()
        graphData.reserveCapacity(pointCount)
        for i in startIndex..<pointCount {
            graphData.append(data[i])
        }
        for i in 0..<startIndex {
            graphData.append(data[i])
        }
        
        graphLayer.values = graphData
    }
    
}

fileprivate class GraphLayer: CAGradientLayer {
    let graphShape = CAShapeLayer()
    
    var lineWidth: CGFloat = 4.0
    var values: [CGFloat] = [0,0] {
        didSet { updateGraphShape() }
    }
    
    override init() {
        super.init()
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        graphShape.fillColor = CGColor(gray: 0.5, alpha: 1.0)
        addSublayer(graphShape)
    }
    
    private func updateGraphShape() {
        let width = bounds.width
        let height = bounds.height * 0.4
        let midH = bounds.height / 2
        
        let size = values.count
        let dx = width / CGFloat(size - 1)
        var x: CGFloat = 0
        
        let path = CGMutablePath()
        
        path.move(to: CGPoint(x: 0, y: midH + height * values[0]))
        for i in 1..<size {
            x += dx
            path.addLine(to: CGPoint(x: x, y: midH + height * values[i])) // NaN Crash here
        }
        
        for i in (0..<size).reversed() {
            path.addLine(to: CGPoint(x: x, y: midH - height * values[i]))
            x -= dx
        }
        
        path.closeSubpath()
        graphShape.path = path
    }
}
