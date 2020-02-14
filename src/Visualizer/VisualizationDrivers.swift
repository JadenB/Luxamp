//
//  VisualizationDrivers.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/23/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

let PREBUILT_DRIVERS = 4

protocol VisualizationDriver {
    var name: String {
        get
    }
	
	var id: Int {
		get
	}
    
    func output(usingAudio audio: AnalyzedAudio) -> Float
}


class VeryLowSpectrumDriver: VisualizationDriver {
    var name: String {
		return "Deep Bass Volume"
    }
	
	var id: Int {
		return 5
	}
    
    func output(usingAudio audio: AnalyzedAudio) -> Float {
        return audio.averageMagOfRange(0...3, withFalloff: 2) * 4
    }
}


class LowSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Bass Volume"
    }
	
	var id: Int {
		return 6
	}
    
    func output(usingAudio audio: AnalyzedAudio) -> Float {
        return audio.averageMagOfRange(0...6, withFalloff: 3) * 5
    }
}


class MidSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Mids Volume"
    }
	
	var id: Int {
		return 7
	}
    
    func output(usingAudio audio: AnalyzedAudio) -> Float {
        return audio.averageMagOfRange(12...20, withFalloff: 3) * 10
    }
}


class HighSpectrumDriver: VisualizationDriver {
    var name: String {
        return "Treble Volume"
    }
	
	var id: Int {
		return 8
	}
    
    func output(usingAudio audio: AnalyzedAudio) -> Float {
        return audio.averageMagOfRange(25...50, withFalloff: 5) * 20
    }
}
