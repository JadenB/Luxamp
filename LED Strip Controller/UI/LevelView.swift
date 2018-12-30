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
    
    @IBInspectable var color: NSColor = .black
    @IBInspectable var backgroundColor: NSColor = .white
    
    @IBInspectable var max: Float = 1.0
    @IBInspectable var min: Float = 0.0
    var level: Float = -Float.infinity {
        didSet {
            needsDisplay = true
        }
    }
    
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
        get {
            return true
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        // Fill background
        backgroundColor.setFill()
        bounds.fill()
        
        if _shouldClear {
            return
        }
        
        // Fill spectrum bars
        color.setFill()
        let viewHeight = CGFloat(bounds.size.height)

        let x = bounds.origin.x
        let y = bounds.origin.y
        let w = bounds.size.width
        let h = viewHeight * CGFloat(remapValueToBounds(level, min: min, max: max))
        
        let r1  = CGRect(x: x, y: y, width: w, height: h)
        r1.fill()
    }
    
    override func prepareForInterfaceBuilder() {
        level = 0.5
    }
    
}
