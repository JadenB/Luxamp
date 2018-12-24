//
//  VisualizationDrivers.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

let PREBUILT_DRIVERS = 5

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
