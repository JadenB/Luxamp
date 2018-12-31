//
//  AdaptiveRange.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation

class AdaptiveRange {
    var maxFilter = BiasedIIRFilter(initialData: [1.0])
    var minFilter = BiasedIIRFilter(initialData: [0.0])
    
    //var upperBound: Float = 1.0
    //var lowerBound: Float = 0.0
    
    var max: Float = 1.0
    var min: Float = 0.0
    
    init() {
        setAlphas()
    }
    
    func calculateRange(forNextValue val: Float) -> (min: Float, max: Float) {
        let newMax = maxFilter.applyFilter(toValue: val, atIndex: 0)
        let newMin = minFilter.applyFilter(toValue: val, atIndex: 0)
        max = newMax
        min = newMin
        return (newMin, newMax)
    }
    
    func reset() {
        maxFilter = BiasedIIRFilter(initialData: [1.0])
        minFilter = BiasedIIRFilter(initialData: [0.0])
        setAlphas()
    }
    
    private func setAlphas() {
        maxFilter.upwardsAlpha = 0.7
        maxFilter.downwardsAlpha = 0.999
        
        minFilter.upwardsAlpha = 0.999
        minFilter.downwardsAlpha = 0.7
    }
}





