//
//  LevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class LegacyLevelView: NSView {
    
    @IBInspectable var color: NSColor = .black
    @IBInspectable var backgroundColor: NSColor = .white
    @IBInspectable var subrangeColor: NSColor = .green
    
    @IBInspectable var max: Float = 1.0
    @IBInspectable var min: Float = 0.0
    var level: Float = -Float.infinity {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable var showSubrange: Bool = false
    @IBInspectable var subrangeMax: Float = 1.0
    @IBInspectable var subrangeMin: Float = 0.0
    
    private var _shouldClear = false
    
    convenience init(min: Float, max: Float) {
        self.init()
        self.min = min
        self.max = max
    }
    
    func disable() {
        _shouldClear = true
        needsDisplay = true
    }
    
    func enable() {
        _shouldClear = false
    }
    
    override var isOpaque: Bool {
        return true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        if _shouldClear {
            return
        }
        
        // Fill level bar
        color.setFill()
        let viewHeight = CGFloat(bounds.size.height)

        let x = bounds.origin.x
        let y = bounds.origin.y
        let w = bounds.size.width
        let h = viewHeight * CGFloat(remapValueToUnit(level, min: min, max: max))
        
        let r1  = CGRect(x: x, y: y, width: w, height: h)
        r1.fill()
        
        if showSubrange {
            subrangeColor.setFill()
            let barHeight: CGFloat = 3.0
            
            // Fill top subrange bar
            let topRect = NSRect(x: x, y: viewHeight * CGFloat(subrangeMax) - barHeight, width: w, height: barHeight)
            topRect.fill()
            
            // Fill bottom subrange bar
            let bottomRect = NSRect(x: x, y: viewHeight * CGFloat(subrangeMin), width: w, height: barHeight)
            bottomRect.fill()
        }
    }
    
    override func prepareForInterfaceBuilder() {
        level = 0.5
    }
    
}
