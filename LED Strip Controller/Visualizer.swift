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
    
    var output: NSColor = .black
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        hue = VisualizerMapper(withEngine: engine)
        brightness = VisualizerMapper(withEngine: engine)
    }

    func visualize() {
        hue.applyMapping()
        brightness.applyMapping()
        let colorToOutput = NSColor(hue: CGFloat(hue.processedVal), saturation: 1.0,
                         brightness: CGFloat(brightness.processedVal), alpha: 1.0)
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
    var processedVal: Float = 0.0
    
    var min: Float = 0.0
    var max: Float = 1.0
    
    var useFilter = true
    var useAdaptiveRange = false
    var invert = false
    
    private var preFilter = BiasedIIRFilter(size: 1)
    var filter = BiasedIIRFilter(size: 1)
    // var range = AdaptiveRange()
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        preFilter.upwardsAlpha = 0.4
        preFilter.downwardsAlpha = 0.4
        filter.upwardsAlpha = 0.5
        filter.downwardsAlpha = 0.5
    }
    
    func applyMapping() {
        guard let d = driver else { return }
        
        rawVal = preFilter.applyFilter(toValue: d.output(usingEngine: engine), atIndex: 0)
        
        var newVal = filter.applyFilter(toValue: rawVal, atIndex: 0)
        newVal = remapValueToBounds(newVal, min: 0.0, max: 1.0)
        
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
