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
    var spectrum: [Float] = [] {
        didSet {
            needsDisplay = true
        }
    }
    
    private var shouldClear = false
    
    convenience init(min: Float, max: Float) {
        self.init()
        self.min = min
        self.max = max
    }
    
    func disable() {
        shouldClear = true
        needsDisplay = true
    }
    
    func enable() {
        shouldClear = false
    }
    
    override var isOpaque: Bool {
        get {
            return true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        let bitmapWidth = spectrum.count
        
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        if shouldClear {
            return
        }
        
        // Fill spectrum bars
        color.setFill()
        let viewHeight = CGFloat(bounds.size.height)
        let xOffset = bounds.origin.x
        var x: CGFloat = 0
        let dx = (bounds.size.width) / CGFloat(bitmapWidth)
        let oneOverWidth = 0.9 / CGFloat(bitmapWidth)
        
        for i in 0 ..< bitmapWidth  {
            let y = bounds.origin.y
            let v = valueAt(position: i, bitmapWidth: bitmapWidth)
            let h = viewHeight * CGFloat( remapValueToBounds(v, min: min, max: max) )
            let w = dx + 1
            
            let r1  = CGRect(x: xOffset + x, y: y, width: w, height: h)
            NSColor(hue: oneOverWidth * CGFloat(i), saturation: 1, brightness: 1, alpha: 1).setFill()
            r1.fill()
            
            x += dx
        }
    }
    
    private func valueAt(position: Int, bitmapWidth: Int) -> Float {
        if(position == bitmapWidth - 1) {
            return spectrum[bitmapWidth - 1]
        }
        let bmapWidthf = Float(bitmapWidth)
        let index: Float = bmapWidthf * (log2f(bmapWidthf) - log2f(Float(bitmapWidth - position))) / log2f(bmapWidthf)
        return spectrum[Int(index)]
        
    }
    
    override func prepareForInterfaceBuilder() {
        spectrum = [Float](repeating: 0.0, count: 256)
        
        for i in 0..<spectrum.count {
            spectrum[i] = min + (max - min) * Float(arc4random()) / Float(UINT32_MAX)
        }
    }
    
}
