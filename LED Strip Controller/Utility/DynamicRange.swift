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
    
    var aggression: Float = 0.5 {
        didSet {
            setAlphas()
        }
    }
    
    init() {
        setAlphas()
    }
    
    func calculateRange(forNextValue val: Float) -> (min: Float, max: Float) {
        let newMax = maxFilter.applyFilter(toValue: val, atIndex: 0)
        let newMin = minFilter.applyFilter(toValue: val, atIndex: 0)
        return (newMin, newMax)
    }
    
    func reset() {
        maxFilter = BiasedIIRFilter(initialData: [1.0])
        minFilter = BiasedIIRFilter(initialData: [0.0])
        setAlphas()
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





