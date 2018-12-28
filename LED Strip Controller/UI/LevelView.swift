//
//  LevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class LevelView: NSView {
    
    var level: Float = -Float.infinity
    @IBInspectable var color: NSColor = .black
    @IBInspectable var backgroundColor: NSColor = .white
    
    @IBInspectable var max: Float = 1.0
    @IBInspectable var min: Float = 0.0
    
    private var shouldClear = false
    
    convenience init(min: Float, max: Float) {
        self.init()
        self.min = min
        self.max = max
    }
    
    func updateLevel(level: Float) {
        self.level = level
        needsDisplay = true
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
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        if shouldClear {
            return
        }
        
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
    
    func remapValueToBounds(_ value: Float) -> Float {
        let scalingFactor = 1 / (max - min)
        return (value - min) * scalingFactor
    }
    
    override func prepareForInterfaceBuilder() {
        updateLevel(level: 0.5)
    }
    
}
