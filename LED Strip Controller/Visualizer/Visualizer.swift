//
//  Visualizer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//
import Cocoa

/// Visualizes data from its AudioEngine to an NSColor
class Visualizer {
    weak var outputDelegate: VisualizerOutputDelegate?
    weak var dataDelegate: VisualizerDataDelegate?
    
    var color: VisualizerMapper
    var brightness: VisualizerMapper
    
    var gradient: NSGradient! = NSGradient(starting: .red, ending: .green)
    
    /// Initializes a Visualizer
    ///
    /// - Parameter engine: The AudioEngine to draw values from. Will be accessed each time visualize() is called.
    init(withEngine engine: AudioEngine) {
        color = VisualizerMapper(withEngine: engine)
        brightness = VisualizerMapper(withEngine: engine)
    }

    /// Produces a color and sends it to the output delegate. Also sends raw brightness and color values to the data delegate.
    func visualize() {
        var outputBrightness: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        
        brightness.applyMapping()
        color.applyMapping()
        outputBrightness = CGFloat(brightness.outputVal)
        
        let gradientColor = gradient.interpolatedColor(atLocation: CGFloat(color.outputVal))
        outputHue = gradientColor.hueComponent
        outputSaturation = gradientColor.saturationComponent
        
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation,
                         brightness: outputBrightness, alpha: 1.0)
        
        outputDelegate?.didVisualizeIntoColor(colorToOutput)
        dataDelegate?.didVisualizeWithData(brightness: brightness.outputVal, color: color.outputVal, inputBrightness: brightness.inputVal, inputColor: color.inputVal)
    }
}

/// Implemented by the Visualizer class to handle brightness and color values seperately. Should not be instantiated outside of a Visualizer.
class VisualizerMapper {
    private var orderedDrivers: [VisualizationDriver] = [PeakEnergyDriver(),
                                                   RootMeanSquareDriver(),
                                                   PitchDriver(),
                                                   SpectralDifferenceDriver(),
                                                   SpectralCrestDriver(),
                                                   VeryLowSpectrumDriver(),
                                                   LowSpectrumDriver(),
                                                   MidSpectrumDriver(),
                                                   HighSpectrumDriver()]
    private var driverDict: [String : VisualizationDriver] = [:]
    
    private var driver: VisualizationDriver
    private var engine: AudioEngine
    
    private var preFilter = BiasedIIRFilter(size: 1)
    private var postFilter = BiasedIIRFilter(size: 1)
    // var range = AdaptiveRange()
    
    fileprivate var inputVal: Float = 0.0
    fileprivate var outputVal: Float = 0.0
    
    var min: Float = 0.0
    var max: Float = 1.0
    
    var useAdaptiveRange = false
    var invert = false
    
    var upwardsSmoothing: Float {
        set {
            postFilter.upwardsAlpha = sqrtf(newValue)
        }
        
        get {
            return postFilter.upwardsAlpha * postFilter.upwardsAlpha
        }
    }
    
    var downwardsSmoothing: Float {
        set {
            postFilter.downwardsAlpha = sqrtf(newValue)
        }
        
        get {
            return postFilter.downwardsAlpha * postFilter.downwardsAlpha
        }
    }
    
    init(withEngine engine: AudioEngine) {
        self.engine = engine
        driver = orderedDrivers[0]
        preFilter.upwardsAlpha = 0.4
        preFilter.downwardsAlpha = 0.4
        postFilter.upwardsAlpha = 0.707
        postFilter.downwardsAlpha = 0.707
        
        for driver in orderedDrivers {
            driverDict[driver.name] = driver
        }
    }
    
    /// Gets the possible driver choices
    ///
    /// - Returns: The names of all possible drivers
    func drivers() -> [String] {
        return orderedDrivers.map { $0.name }
    }
    
    /// Gets the name of the current driver
    ///
    /// - Returns: The name of the current driver
    func driverName() -> String {
        return driver.name
    }
    
    /// Sets the current driver
    ///
    /// - Parameter name: The name of the driver to set
    func setDriver(withName name: String) {
        driver = driverDict[name] ?? orderedDrivers[0]
    }
    
    /// Transforms the value given by the driver and sets inputVal and outputVal
    fileprivate func applyMapping() {
        inputVal = preFilter.applyFilter(toValue: driver.output(usingEngine: engine), atIndex: 0)
        
        var newVal = postFilter.applyFilter(toValue: inputVal, atIndex: 0)
        
        // adaptive range code here
        
        newVal = remapValueToBounds(newVal, min: min, max: max)
        
        
        if invert {
            newVal = 1.0 - newVal
        }
        
        outputVal = newVal
    }
}

/// The output delegate of a Visualizer object implements this protocol to perform specialized actions when the visualizer produces a color
protocol VisualizerOutputDelegate: class {
    func didVisualizeIntoColor(_ color: NSColor)
}

/// The data delegate of a Visualizer object implements this protocol to perform specialized actions when the visualizer converts data to color and brightness
protocol VisualizerDataDelegate: class {
    func didVisualizeWithData(brightness: Float, color: Float, inputBrightness: Float, inputColor: Float)
}
