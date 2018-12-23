//
//  SpectrumView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class SpectrumView: NSView {
    
    var spectrumArray: [Double] = []
    var color = NSColor.black
    var backgroundColor = NSColor.white
    
    var max: Double = 0
    var min: Double = -72
    
    func updateSpectrum(spectrum: [Double]) {
        spectrumArray = spectrum
        needsDisplay = true
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
        
        var lastX = x // log
        
        for i in 0 ..< bitmapWidth  {
            let y = bounds.origin.y
            let h = viewHeight * CGFloat( remapValueToBounds(spectrumArray[i]) )
            var w = ceil(dx) + 1
            x = linearToExponential(data: Double(i+1),
                        screenY0: 0, screenY1: bounds.size.width,
                        dataY0: 1, dataY1: CGFloat(bitmapWidth)) // log
            w = x - lastX + 1 // log
            
            //let r1  = CGRect(x: xOffset + x, y: y, width: w, height: h)
            let r1  = CGRect(x: xOffset + lastX, y: y, width: w, height: h) // log
            NSColor(hue: CGFloat(i)/CGFloat(bitmapWidth), saturation: 1, brightness: 1, alpha: 1).setFill()
            r1.fill()
            
            lastX = x // log
            x += dx
        }
    }
    
    func linearToExponential(data: Double, screenY0:CGFloat, screenY1:CGFloat, dataY0:Double, dataY1:CGFloat) ->CGFloat{
        return screenY0 + (log(CGFloat(data)) - log(CGFloat(dataY0))) / (log(CGFloat(dataY1)) - log(CGFloat(dataY0))) * (screenY1 - screenY0)
    }
    
    func remapValueToBounds(_ value: Double) -> Double {
        if value > max {
            return 1.0
        } else if value < min {
            return 0.0
        }
        let scalingFactor = 1 / (max - min)
        return (value - min) * scalingFactor
    }
    
}
