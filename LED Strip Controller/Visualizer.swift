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
                                          SpectralCrestDriver()]
    var delegate: VisualizerOutputDelegate?
    var dataDelegate: VisualizerDataDelegate?
    
    var hue: VisualizerMapper
    var brightness: VisualizerMapper
    
    var colorGradient: NSGradient! = NSGradient(starting: .red, ending: .yellow)
    var useGradient = false
    
    var output: NSColor = .black
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        hue = VisualizerMapper(withEngine: engine)
        brightness = VisualizerMapper(withEngine: engine)
    }

    func visualize() {
        var outputBrightness: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        
        brightness.applyMapping()
        hue.applyMapping()
        outputBrightness = CGFloat(brightness.processedVal)
        
        if useGradient {
            let gradientColor = colorGradient.interpolatedColor(atLocation: CGFloat(hue.processedVal))
            outputHue = gradientColor.hueComponent
            outputSaturation = gradientColor.saturationComponent
        } else {
            outputHue = CGFloat(hue.processedVal)
        }
        
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation,
                         brightness: outputBrightness, alpha: 1.0)
        
        delegate?.didVisualizeIntoColor(colorToOutput)
        dataDelegate?.didVisualizeWithData(brightness: brightness.processedVal, hue: hue.processedVal, rawBrightness: brightness.rawVal, rawHue: hue.rawVal)
        output = colorToOutput
    }
    
    func setHueDriver(id: Int) {
        hue.driver = drivers[id]
    }
    
    func setBrightnessDriver(id: Int) {
        brightness.driver = drivers[id]
    }
    
    func setCustomHueDriver(driver: VisualizationDriver) {
        hue.driver = driver
    }
    
    func setCustomBrightnessDriver(driver: VisualizationDriver) {
        brightness.driver = driver
    }
}

class VisualizerMapper {
    fileprivate var driver: VisualizationDriver?
    fileprivate var engine: AudioEngine
    
    var rawVal: Float = 0.0
    var mappedVal: Float = 0.0
    var processedVal: Float = 0.0
    
    var min: Float = 0.0
    var max: Float = 1.0
    
    var useFilter = true
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
            return 0.0 // don't need this
        }
    }
    
    var downwardsSmoothing: Float {
        set {
            filter.downwardsAlpha = sqrtf(newValue)
        }
        
        get {
            return 0.0 // don't need this
        }
    }
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        preFilter.upwardsAlpha = 0.4
        preFilter.downwardsAlpha = 0.4
        filter.upwardsAlpha = 0.707
        filter.downwardsAlpha = 0.707
    }
    
    func applyMapping() {
        guard let d = driver else { return }
        
        rawVal = preFilter.applyFilter(toValue: d.output(usingEngine: engine), atIndex: 0)
        
        var newVal = filter.applyFilter(toValue: rawVal, atIndex: 0) //Swap these two lines once range slider is implemented for output
        newVal = remapValueToBounds(newVal, min: min, max: max) //
        
        
        if invert {
            newVal = 1.0 - newVal
        }
        
        processedVal = newVal
    }
}

protocol VisualizerOutputDelegate {
    func didVisualizeIntoColor(_ color: NSColor)
}

protocol VisualizerDataDelegate {
    func didVisualizeWithData(brightness: Float, hue: Float, rawBrightness: Float, rawHue: Float)
}
