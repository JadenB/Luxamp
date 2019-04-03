//
//  DynamicRange.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation

fileprivate let ALPHA_MAX: Float = 0.9995
fileprivate let ALPHA_MIN: Float = 0.995

class DynamicRange {
    var maxFilter = BiasedIIRFilter(initialData: [1.0])
    var minFilter = BiasedIIRFilter(initialData: [0.0])
    
    /// Whether the dynamic subrange calculates a new maximum.
    var useMax = true 
    /// Whether the dynamic subrange calculates a new minimum.
    var useMin = true
    
    var aggression: Float = 0.5 {
        didSet {
            setAlphas()
        }
    }
    
    init() {
        setAlphas()
    }
    
    func calculateRange(forNextValue val: Float) -> (min: Float, max: Float) {
        var newMax: Float = 1.0
        var newMin: Float = 0.0
        
        if useMax {
            newMax = maxFilter.applyFilter(toValue: val, atIndex: 0)
        }
        
        if useMin {
            newMin = minFilter.applyFilter(toValue: val, atIndex: 0)
        }
        
        
        return (newMin, newMax)
    }
    
    func resetRange() {
        maxFilter = BiasedIIRFilter(initialData: [1.0])
        minFilter = BiasedIIRFilter(initialData: [0.0])
        setAlphas()
    }
	
	func set(min: Float, max: Float) {
		maxFilter = BiasedIIRFilter(initialData: [max])
		minFilter = BiasedIIRFilter(initialData: [min])
	}
    
    private func setAlphas() {
        maxFilter.upwardsAlpha = 0.6
        maxFilter.downwardsAlpha = remapValueToBounds(sqrtf(1 - aggression),
                                                      inputMin: 0.0, inputMax: 1.0,
                                                      outputMin: ALPHA_MIN, outputMax: ALPHA_MAX)
        
        minFilter.upwardsAlpha = maxFilter.downwardsAlpha
        minFilter.downwardsAlpha = maxFilter.upwardsAlpha
    }
}





