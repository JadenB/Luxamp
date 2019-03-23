//
//  AdjustableLevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 3/13/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class AdjustableLevelView: NSControl {
    
    @IBInspectable var max: Float = 1.0
    @IBInspectable var min: Float = 0.0
    
    @IBInspectable var upperSlider: CGFloat = 0.75
    @IBInspectable var lowerSlider: CGFloat = 0.25
    
    @IBInspectable var backgroundColor: NSColor = .black
    @IBInspectable var color: NSColor = .red
    @IBInspectable var sliderColor: NSColor = .green
    
    var level: Float = 0.5 {
        willSet {
            if level > min || newValue > min { needsDisplay = true }
        }
    }
    
    private var tracking: TrackingStatus = .None
    private var lowerSliderRect: NSRect = .zero
    private var upperSliderRect: NSRect = .zero
    private var prevMousePos: CGFloat = 0.0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        backgroundColor.setFill()
        dirtyRect.fill()
        
        let h = bounds.size.height
        let w = bounds.size.width
        
        color.setFill()
        NSRect(x: 0.0, y: 0.0, width: w, height: CGFloat(level) * h).fill()
        
        let sliderHeight: CGFloat = 6.0
        sliderColor.setFill()
        
        // Fill top subrange bar
        upperSliderRect = NSRect(x: 0.0, y: h * upperSlider - sliderHeight, width: w, height: sliderHeight)
        upperSliderRect.fill()
        
        // Fill bottom subrange bar
        lowerSliderRect = NSRect(x: 0.0, y: h * lowerSlider, width: w, height: sliderHeight)
        lowerSliderRect.fill()
        
    }
    
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
        let loc = convert(event.locationInWindow, from: window?.contentView)
        if upperSliderRect.contains(loc) {
            tracking = .UpperSlider
            prevMousePos = loc.y
        } else if lowerSliderRect.contains(loc) {
            tracking = .LowerSlider
            prevMousePos = loc.y
        }
    }
    
    override func mouseUp(with event: NSEvent) {
        super.mouseUp(with: event)
        // stop tracking
        if tracking != .None {
            resetCursorRects()
            tracking = .None
        }
    }
    
    override func mouseDragged(with event: NSEvent) {
        super.mouseDragged(with: event)
        
        if tracking == .None {
            return
        }
        
        let loc = convert(event.locationInWindow, from: window?.contentView)
        let delta = (loc.y - prevMousePos) / bounds.height
        var oldPos: CGFloat = 0.0
        
        if tracking == .UpperSlider {
            oldPos = upperSlider
        } else if tracking == .LowerSlider {
            oldPos = lowerSlider
        }
        
        var newPos = oldPos + delta
        if newPos > 1.0 {
            newPos = 1.0
        } else if newPos < 0.0 {
            newPos = 0.0
        }
        
        if tracking == .UpperSlider && newPos > lowerSlider {
            upperSlider = newPos
        } else if tracking == .LowerSlider && newPos < upperSlider {
            lowerSlider = newPos
        }
        
        prevMousePos = loc.y
        needsDisplay = true
    }
    
    override var isOpaque: Bool {
        return true
    }
    
    enum TrackingStatus {
        case UpperSlider
        case LowerSlider
        case None
    }
    
}
