//
//  Visualizer.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//
import Cocoa

let USERDEFAULTS_MAX_BRIGHTNESS_KEY = "maxBrightness"

/// Visualizes data from its AudioEngine to an NSColor
class Visualizer {
    weak var outputDelegate: VisualizerOutputDelegate?
    weak var dataDelegate: VisualizerDataDelegate?
    
    var color: VisualizerMapper
    var brightness: VisualizerMapper
    
    var maxBrightness: Float = 1.0 {
        didSet {
            UserDefaults.standard.set(maxBrightness, forKey: USERDEFAULTS_MAX_BRIGHTNESS_KEY)
        }
    }
    var minBrightness: Float = 0.0
    
    var gradient: NSGradient! = NSGradient(starting: .red, ending: .green)
    
    /// Initializes a Visualizer
    ///
    /// - Parameter engine: The AudioEngine to draw values from. Will be accessed each time visualize() is called.
    init(withEngine engine: AudioEngine) {
        color = VisualizerMapper(withEngine: engine)
        brightness = VisualizerMapper(withEngine: engine)
        
        if UserDefaults.standard.object(forKey: USERDEFAULTS_MAX_BRIGHTNESS_KEY) != nil {
            maxBrightness = UserDefaults.standard.float(forKey: USERDEFAULTS_MAX_BRIGHTNESS_KEY)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(maxBrightnessChanged), name: .didChangeMaxBrightness, object: nil)
    }

    /// Produces a color and sends it to the output delegate. Also sends raw brightness and color values to the data delegate.
    func visualize() {
        // Setup components of color
        var outputBrightness: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        
        // Calculate raw values from brightness and color mappers
        brightness.applyMapping()
        color.applyMapping()
        
        // Convert raw color mapping to hue and saturation with the gradient
        let gradientColor = gradient.interpolatedColor(atLocation: CGFloat(color.outputVal))
        
        // Set the final color components
        outputBrightness = CGFloat(remapValueToBounds(brightness.outputVal, inputMin: 0.0, inputMax: 1.0, outputMin: minBrightness, outputMax: maxBrightness))
        outputHue = gradientColor.hueComponent
        outputSaturation = gradientColor.saturationComponent
        
        // Send the color to the output delegate
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation, brightness: outputBrightness, alpha: 1.0)
        outputDelegate?.didVisualizeIntoColor(colorToOutput)
        
        // Send the data to the data delegate
        let data = VisualizerData()
        
        data.outputBrightness = brightness.outputVal
        data.inputBrightness = brightness.inputVal
        data.dynamicBrightnessRange.max = brightness.dynamicMax
        data.dynamicBrightnessRange.min = brightness.dynamicMin
        
        data.outputColor = color.outputVal
        data.inputColor = color.inputVal
        data.dynamicColorRange.max = color.dynamicMax
        data.dynamicColorRange.min = color.dynamicMin
        
        dataDelegate?.didVisualizeWithData(data)
    }
    
    @objc func maxBrightnessChanged(_ notification: Notification) {
        if let userInfo = notification.userInfo as? [String:Float] {
            maxBrightness = userInfo["maxBrightness"] ?? 1.0
        }
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
    
    /// The raw input value from the driver, set when applyMapping() is called
    fileprivate var inputVal: Float = 0.0
    /// The mapped output value, calculated when applyMapping() is called
    fileprivate var outputVal: Float = 0.0
    
    // TODO: convert these to something like range.max and range.min
    // The range of input values that applyMapping() remaps to the range 0-1
    var inputMin: Float = 0.0
    var inputMax: Float = 1.0
    
    /// The dynamic subrange between 0 and 1 calculated by applyMapping() when useDynamicRange is true
    fileprivate var dynamicMin: Float = 0.0
    fileprivate var dynamicMax: Float = 1.0
    
    /// Whether to invert the input range
    var invert = false
    
    /// Whether to use a dynamic subrange on the input range
    var useDynamicRange = false {
        didSet {
            if !useDynamicRange { dynamicRange.reset() }
        }
    }
    
    /// Whether the dynamic subrange calculates a new minimum. Has no effect if useDynamicRange is false
    var useDynamicMin = true
    /// Whether the dynamic subrange calculates a new maximum. Has no effect if useDynamicRange is false
    var useDynamicMax = true
    
    var dynamicRange = DynamicRange()
    
    var upwardsSmoothing: Float {
        get {
            return postFilter.upwardsAlpha * postFilter.upwardsAlpha
        }
        set {
            postFilter.upwardsAlpha = sqrtf(newValue)
        }
    }
    
    var downwardsSmoothing: Float {
        get {
            return postFilter.downwardsAlpha * postFilter.downwardsAlpha
        }
        set {
            postFilter.downwardsAlpha = sqrtf(newValue)
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
        newVal = remapValueToBounds(newVal, min: inputMin, max: inputMax)
        
        if useDynamicRange {
            let range = dynamicRange.calculateRange(forNextValue: newVal)
            dynamicMin = useDynamicMin ? range.min : 0.0
            dynamicMax = useDynamicMax ? range.max : 1.0
            newVal = remapValueToBounds(newVal, min: range.min, max: range.max)
        }
        
        if invert {
            newVal = 1.0 - newVal
        }
        
        outputVal = newVal
    }
}

// A container meant to consolidate output data from the visualizer to pass to its data delegate
class VisualizerData {
    var inputBrightness: Float = 0.0
    var outputBrightness: Float = 0.0
    var dynamicBrightnessRange: (min: Float, max: Float) = (0,0)
    
    var inputColor: Float = 0.0
    var outputColor: Float = 0.0
    var dynamicColorRange: (min: Float, max: Float) = (0,0)
}

/// The output delegate of a Visualizer object implements this protocol to perform specialized actions when the visualizer produces a color
protocol VisualizerOutputDelegate: class {
    func didVisualizeIntoColor(_ color: NSColor)
}

/// The data delegate of a Visualizer object implements this protocol to perform specialized actions when the visualizer converts data to color and brightness
protocol VisualizerDataDelegate: class {
    func didVisualizeWithData(_ data: VisualizerData)
}
