//
//  LevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class LevelView: NSView {
    
    var level: Double = -Double.infinity
    var color = NSColor.black
    var backgroundColor = NSColor.white
    
    var max: Double = 1.0
    var min: Double = 0.0
    
    func updateLevel(level: Double) {
        self.level = level
        needsDisplay = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        // Fill spectrum bars
        color.setFill()
        let viewHeight = CGFloat(bounds.size.height)

        let x = bounds.origin.x
        let y = bounds.origin.y
        let w = bounds.size.width
        let h = viewHeight * CGFloat(remapValueToBounds(level))
        
        let r1  = CGRect(x: x, y: y, width: w, height: h)
        r1.fill()
    }
    
    func remapValueToBounds(_ value: Double) -> Double {
        let scalingFactor = 1 / (max - min)
        return (value - min) * scalingFactor
    }
    
}