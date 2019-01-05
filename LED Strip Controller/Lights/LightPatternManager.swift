//
//  LightPatterns.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/28/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

// TODO: Move lightpatternmanager references from lightcontroller to viewcontroller
// each mode's callback should check if appmode is its respective mode (e.g. didvisualizewithcolor should start with a check if appmode == .music)
class LightPatternManager {
    
    weak var delegate: LightPatternManagerDelegate?
    
    var pattern: LightPattern {
        return currentPattern
    }
    
    var isActive: Bool {
        return timer != nil
    }
    
    private var timer: Timer?
    private var elapsedCycles: Int64 = 0
    private var currentPattern: LightPattern = .Strobe
    private var period: Double =  1.0
    private var useRefreshRate = false // Set to true if using a pattern whose refresh rate is period-independant
    private var refreshRate = 60.0 // how many times the pattern updates the delegate per second
    
    func start(withPattern newPattern: LightPattern, andPeriod newPeriod: Double) {
        if isActive {
            stop()
        }
        
        period = newPeriod
        
        switch newPattern {
        case .Strobe:
            useRefreshRate = false
        case .Fade:
            useRefreshRate = true
        case .Jump:
            useRefreshRate = false
        case .Candle:
            useRefreshRate = true
        }
        
        currentPattern = newPattern
        elapsedCycles = 0
        
        let interval = useRefreshRate ? (1 / refreshRate) : period
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(update), userInfo: nil, repeats: true)
        timer?.fire()
    }
    
    func stop() {
        if !isActive { return }
        timer?.invalidate()
        timer = nil
    }
    
    @objc func update() {
        switch currentPattern {
        case .Strobe:
            delegate?.didGenerateColorFromPattern(generateStrobeColor())
        case .Fade:
            delegate?.didGenerateColorFromPattern(generateFadeColor())
        case .Jump:
            delegate?.didGenerateColorFromPattern(generateJumpColor())
        case .Candle:
            delegate?.didGenerateColorFromPattern(generateCandleColor())
        }
        
        elapsedCycles += 1
    }
    
    func generateStrobeColor() -> NSColor {
        return elapsedCycles % 2 == 0 ? .white : .black
    }
    
    func generateJumpColor() -> NSColor {
        let colorIndex = elapsedCycles % 7
        switch colorIndex {
        case 0:
            return .red
        case 1:
            return .orange
        case 2:
            return .yellow
        case 3:
            return .green
        case 4:
            return .cyan
        case 5:
            return .blue
        case 6:
            return .magenta
        default:
            return .white
        }
    }
    
    func generateFadeColor() -> NSColor {
        let hue = (Double(elapsedCycles) / (period * refreshRate * 7)).truncatingRemainder(dividingBy: 1.0)
        return NSColor(hue: CGFloat(hue), saturation: 1.0, brightness: 1.0, alpha: 1.0)
    }
    
    func generateCandleColor() -> NSColor {
        return .orange
    }
}

protocol LightPatternManagerDelegate: class {
    func didGenerateColorFromPattern(_ color: NSColor)
}

enum LightPattern {
    case Strobe
    case Fade
    case Jump
    case Candle
}
