//
//  VisualizationDrivers.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

let PREBUILT_DRIVERS = 9

protocol VisualizationDriver {
    var name: String {
        get
    }
    
    func output(usingEngine engine: AudioEngine) -> Float
}

/* CLASSES */
// 1
class RootMeanSquareDriver: VisualizationDriver {
    var name: String {
        get {
            return "Root Mean Square"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.gist.rootMeanSquare()
    }
}

// 2
class PeakEnergyDriver: VisualizationDriver {
    var name: String {
        get {
            return "Peak Energy"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.gist.peakEnergy()
    }
}

// 3
class SpectralDifferenceDriver: VisualizationDriver {
    var name: String {
        get {
            return "Spectral Difference"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.gist.spectralDifference()
    }
}

// 4
class SpectralCrestDriver: VisualizationDriver {
    var name: String {
        get {
            return "Spectral Crest"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.gist.spectralCrest()
    }
}


// 5
class PitchDriver: VisualizationDriver {
    var name: String {
        get {
            return "Pitch"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.gist.pitch()
    }

}

// 6
class VeryLowSpectrumDriver: VisualizationDriver {
    var name: String {
        get {
            return "Very Low Spectrum"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(0...3, withFalloff: 2) * 0.0075
    }
}

// 7
class LowSpectrumDriver: VisualizationDriver {
    var name: String {
        get {
            return "Low Spectrum"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(0...6, withFalloff: 3) * 0.01
    }
}

// 8
class MidSpectrumDriver: VisualizationDriver {
    var name: String {
        get {
            return "Mid Spectrum"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(12...20, withFalloff: 3) * 0.02
    }
}

// 9
class HighSpectrumDriver: VisualizationDriver {
    var name: String {
        get {
            return "High Spectrum"
        }
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(25...50, withFalloff: 5) * 0.04
    }
}


// Unused, left for a possible custom driver functionality
/*
class PartialMagnitudeSpectrumDriver: VisualizationDriver {
    
    var name: String {
        get {
            return "Magnitude Spectrum..."
        }
    }
    
    let falloff: Int
    let startIndex: Int
    let endIndex: Int
    
    init(first: Int, last: Int, falloff: Int) {
        startIndex = first
        endIndex = last
        self.falloff = falloff
    }
    
    func output(usingEngine engine: AudioEngine) -> Float {
        return engine.bProcessor.averageMagOfRange(startIndex...endIndex, withFalloff: falloff) * 0.01
    }
    
}*/
