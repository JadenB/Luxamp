//
//  VisualizerTextField.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class VisualizerTextField: NSTextField {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func keyUp(with event: NSEvent) {
        super.keyUp(with: event)
        if event.keyCode == 53 {
            window?.makeFirstResponder(nil)
        }
    }
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }
    
}
