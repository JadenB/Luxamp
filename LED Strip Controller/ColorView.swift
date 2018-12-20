//
//  ColorView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class ColorView: NSView {
    
    private var _color: NSColor = NSColor.white
    
    var fillColor: NSColor {
        get {
            return _color
        }
        set {
            _color = newValue
            needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        fillColor.setFill()
        dirtyRect.fill()
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
