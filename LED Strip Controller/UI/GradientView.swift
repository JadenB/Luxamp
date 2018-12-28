//
//  GradientView.swift
//  LED Strip Controller
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
    }
    
}
