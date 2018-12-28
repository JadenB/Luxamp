//
//  Visualizer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//
import Cocoa

class Visualizer {
    var engine: AudioEngine
    var drivers: [VisualizationDriver] = [PeakEnergyDriver(),
                                          RootMeanSquareDriver(),
                                          PitchDriver(),
                                          SpectralDifferenceDriver(),
                                          SpectralCrestDriver(),
                                          VeryLowSpectrumDriver(),
                                          LowSpectrumDriver(),
                                          MidSpectrumDriver(),
                                          HighSpectrumDriver()]
    private var driverDict: [String : VisualizationDriver] = [:]
    
    var delegate: VisualizerOutputDelegate?
    var dataDelegate: VisualizerDataDelegate?
    
    var hue: VisualizerMapper
    var brightness: VisualizerMapper
    
    var gradient: NSGradient! = NSGradient(starting: .red, ending: .green)
    var useGradient = true
    
    var output: NSColor = .black
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        hue = VisualizerMapper(withEngine: engine, andDriver: drivers[0])
        brightness = VisualizerMapper(withEngine: engine, andDriver: drivers[0])
        
        for driver in drivers {
            driverDict[driver.name] = driver
        }
    }

    func visualize() {
        var outputBrightness: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        
        brightness.applyMapping()
        hue.applyMapping()
        outputBrightness = CGFloat(brightness.mappedVal)
        
        if useGradient {
            let gradientColor = gradient.interpolatedColor(atLocation: CGFloat(hue.mappedVal))
            outputHue = gradientColor.hueComponent
            outputSaturation = gradientColor.saturationComponent
        } else {
            outputHue = CGFloat(hue.mappedVal)
        }
        
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation,
                         brightness: outputBrightness, alpha: 1.0)
        
        delegate?.didVisualizeIntoColor(colorToOutput)
        dataDelegate?.didVisualizeWithData(brightness: brightness.mappedVal, hue: hue.mappedVal, inputBrightness: brightness.inputVal, inputHue: hue.inputVal)
        output = colorToOutput
    }
    
    func setHueDriver(name: String) {
        hue.driver = driverDict[name]!
    }
    
    func setBrightnessDriver(name: String) {
        brightness.driver = driverDict[name]!
    }
}

class VisualizerMapper {
    var driver: VisualizationDriver
    fileprivate var engine: AudioEngine
    
    var inputVal: Float = 0.0
    var mappedVal: Float = 0.0
    
    var min: Float = 0.0
    var max: Float = 1.0

    var useAdaptiveRange = false
    var invert = false
    
    private var preFilter = BiasedIIRFilter(size: 1)
    var filter = BiasedIIRFilter(size: 1)
    // var range = AdaptiveRange()
    
    var upwardsSmoothing: Float {
        set {
            filter.upwardsAlpha = sqrtf(newValue)
        }
        
        get {
            return filter.upwardsAlpha * filter.upwardsAlpha
        }
    }
    
    var downwardsSmoothing: Float {
        set {
            filter.downwardsAlpha = sqrtf(newValue)
        }
        
        get {
            return filter.downwardsAlpha * filter.downwardsAlpha
        }
    }
    
    init(withEngine engine: AudioEngine, andDriver d: VisualizationDriver) {
        self.engine = engine
        driver = d
        preFilter.upwardsAlpha = 0.4
        preFilter.downwardsAlpha = 0.4
        filter.upwardsAlpha = 0.707
        filter.downwardsAlpha = 0.707
    }
    
    func applyMapping() {
        inputVal = preFilter.applyFilter(toValue: driver.output(usingEngine: engine), atIndex: 0)
        
        var newVal = filter.applyFilter(toValue: inputVal, atIndex: 0)
        
        // adaptive range code here
        
        newVal = remapValueToBounds(newVal, min: min, max: max)
        
        
        if invert {
            newVal = 1.0 - newVal
        }
        
        mappedVal = newVal
    }
}

protocol VisualizerOutputDelegate {
    func didVisualizeIntoColor(_ color: NSColor)
}

protocol VisualizerDataDelegate {
    func didVisualizeWithData(brightness: Float, hue: Float, inputBrightness: Float, inputHue: Float)
}
