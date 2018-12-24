//
//  SpectrumView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class SpectrumView: NSView {
    
    var spectrumArray: [Float] = []
    var color = NSColor.black
    var backgroundColor = NSColor.white
    
    var max: Float = 1.0
    var min: Float = 0.0
    
    convenience init(min: Float, max: Float) {
        self.init()
        self.min = min
        self.max = max
    }
    
    func updateSpectrum(spectrum: [Float]) {
        spectrumArray = spectrum
        needsDisplay = true
    }
    
    override var isOpaque: Bool {
        get {
            return true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let bitmapWidth = spectrumArray.count
        
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        // Fill spectrum bars
        color.setFill()
        let viewHeight = CGFloat(bounds.size.height)
        let xOffset = bounds.origin.x
        var x: CGFloat = 0
        let dx = (bounds.size.width) / CGFloat(bitmapWidth)
        
        for i in 0 ..< bitmapWidth  {
            let y = bounds.origin.y
            let v = valueAt(position: i, bitmapWidth: bitmapWidth)
            let h = viewHeight * CGFloat( remapValueToBounds(v) )
            let w = dx + 1
            
            let r1  = CGRect(x: xOffset + x, y: y, width: w, height: h)
            NSColor(hue: 0.9 * CGFloat(i)/CGFloat(bitmapWidth), saturation: 1, brightness: 1, alpha: 1).setFill()
            r1.fill()
            
            x += dx
        }
    }
    
    func valueAt(position: Int, bitmapWidth: Int) -> Float {
        if(position == bitmapWidth - 1) {
            return spectrumArray[bitmapWidth - 1]
        }
        let index: Float = Float(bitmapWidth) * (log2f(Float(bitmapWidth)) - log2f(Float(bitmapWidth - position))) / log2f(Float(bitmapWidth))
        return spectrumArray[Int(index)]
        
    }
    
    func remapValueToBounds(_ value: Float) -> Float {
        if value > max {
            return 1.0
        } else if value < min {
            return 0.0
        }
        let scalingFactor = 1 / (max - min)
        return (value - min) * scalingFactor
    }
    
}
