//
//  LightPatterns.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/28/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class LightPatternManager {
    
    var elapsedCycles: Int64 = 0
    var isActive = false
    let controller: LightController
    let timer = Timer()
    var refreshRate = 0.0 {
        didSet {
            // invalidate and recreate timer
        }
    }
    
    init(withController c: LightController) {
        controller = c
    }
    
    func select(pattern: LightPattern) {
        switch pattern {
        case .Strobe:
            break
        case .Fade:
            break
        case .Jump:
            break
        case .Candle:
            break
        default:
            break
        }
        elapsedCycles = 0
    }
    
    func start() {
        isActive = true
    }
    
    func stop() {
        isActive = false
    }
    
    @objc func updateColor() {
        //controller.setColor(color: ) <- current driver
    }
}

protocol LightPatternDriver {
    func calculateColor(atTime t: Int64) -> NSColor
}
