//
//  VisualizationDrivers.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

let PREBUILT_DRIVERS = 9

protocol VisualizationDriver {
    var name: String {
        get
    }
	
	var id: Int {
		get
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float
}

/* CLASSES */
// 1
class RootMeanSquareDriver: VisualizationDriver {
    var name: String {
        return "Average Volume"
    }
	
	var id: Int {
		return 0
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.gist.rootMeanSquare() * 1.5
    }
}

// 2
class PeakEnergyDriver: VisualizationDriver {
    var name: String {
        return "Peak Volume"
    }
	
	var id: Int {
		return 1
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.gist.peakEnergy()
    }
}

// 3
class SpectralDifferenceDriver: VisualizationDriver {
    var name: String {
        return "Spectral Difference"
    }
	
	var id: Int {
		return 2
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.gist.spectralDifference() * 0.0006
    }
}

// 4
class SpectralCrestDriver: VisualizationDriver {
    var name: String {
        return "Spectral Crest"
    }
	
	var id: Int {
		return 3
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.gist.spectralCrest() * 0.0014
    }
}


// 5
class PitchDriver: VisualizationDriver {
    var name: String {
        return "Pitch"
    }
	
	var id: Int {
		return 4
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.gist.pitch() * 0.00125
    }

}

// 6
class VeryLowSpectrumDriver: VisualizationDriver {
    var name: String {
		return "Deep Bass Volume"
    }
	
	var id: Int {
		return 5
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.averageMagOfRange(0...3, withFalloff: 2) * 0.0075
    }
}

// 7
class LowSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Bass Volume"
    }
	
	var id: Int {
		return 6
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.averageMagOfRange(0...6, withFalloff: 3) * 0.01
    }
}

// 8
class MidSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Mids Volume"
    }
	
	var id: Int {
		return 7
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.averageMagOfRange(12...20, withFalloff: 3) * 0.02
    }
}

// 9
class HighSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Treble Volume"
    }
	
	var id: Int {
		return 8
	}
    
    func output(usingBuffer buffer: AnalyzedBuffer) -> Float {
        return buffer.averageMagOfRange(25...50, withFalloff: 5) * 0.04
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
