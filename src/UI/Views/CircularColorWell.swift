//
//  CircularColorWell.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/19/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class CircularColorWell: NSColorWell {
    
    let circleLayer = CAShapeLayer()
    
    override var color: NSColor {
        didSet {
            circleLayer.fillColor = color.cgColor
            needsDisplay = true
        }
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override var wantsLayer: Bool {
        get { return true }
        set { return }
    }
    
    override func makeBackingLayer() -> CALayer {
        let l = circleLayer
        l.frame = bounds
        l.path = CGPath(ellipseIn: bounds, transform: nil)
        l.fillColor = NSColor.black.cgColor
        l.needsDisplayOnBoundsChange = true
        return l
    }
    
    override func prepareForInterfaceBuilder() {
        color = NSColor.red
    }
    
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: window?.contentView)
        if circleLayer.path?.contains(p) ?? false {
            super.mouseDown(with: event)
            //i love cock
        }
    }
}
