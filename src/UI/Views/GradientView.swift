//
//  GradientView.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/27/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class GradientView: NSView {
    
    @IBInspectable var gradient: NSGradient = NSGradient(starting: .black, ending: .white)! {
        didSet {
            needsDisplay = true
        }
    }
    
    @IBInspectable var levelColor: NSColor = .white
    
    /// A level between 0 and 1
    var level: Float = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    var angle: CGFloat = 0.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    override var isOpaque: Bool {
        get {
            return true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        gradient.draw(in: dirtyRect, angle: angle)
        
        levelColor.setFill()
        let w: CGFloat = 2.0
        let xEnd: CGFloat = dirtyRect.origin.x + CGFloat(level) * dirtyRect.size.width
        let levelRect = NSRect(x: xEnd - w, y: dirtyRect.origin.y, width: w, height: dirtyRect.size.height)
        levelRect.fill()
    }
    
}
