//
//  Visualizer.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/20/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//
import Cocoa

/// Visualizes data from its AudioEngine to an NSColor
class Visualizer {
    weak var delegate: VisualizerDelegate?
    
    var presets: VisualizerPresetManager
    
    var color: VisualizerMapper
    var brightness: VisualizerMapper
    
    /// The gradient used to map the output color
    var gradient: NSGradient! = NSGradient(starting: .red, ending: .yellow)
    
    /// Initializes a Visualizer
    ///
    /// - Parameter engine: The AudioEngine to draw values from. Will be accessed each time visualize() is called.
    init() {
        color = VisualizerMapper()
        brightness = VisualizerMapper()
		presets = VisualizerPresetManager()
        presets.visualizer = self
        presets.apply(name: PRESETMANAGER_DEFAULT_PRESET_NAME)
    }
    
    /// Produces a color and sends it to the output delegate. Also sends raw brightness and color values to the data delegate.
    func visualizeBuffer(_ buffer: AudioMapper) {
        // Setup components of color
        var outputBrightness: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        
        // Calculate raw values from brightness and color mappers
        let brightnessData = brightness.generateMapping(fromBuffer: buffer)
        let colorData = color.generateMapping(fromBuffer: buffer)
        
        // Convert raw color mapping to hue and saturation with the gradient
        let gradientColor = gradient.interpolatedColor(atLocation: CGFloat(colorData.outputVal))
        
        // Set the final color components, ignoring brightness of gradient
        outputBrightness = CGFloat(brightnessData.outputVal)
        outputSaturation = gradientColor.saturationComponent
        outputHue = gradientColor.hueComponent
        
        // Send the computed color and associated data to the delegate
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation, brightness: outputBrightness, alpha: 1.0)
        delegate?.didVisualizeIntoColor(colorToOutput, brightnessVal: brightnessData.outputVal, colorVal: colorData.outputVal)
        delegate?.didVisualizeWithData(brightnessData: brightnessData, colorData: colorData)
    }
}

/// Implemented by the Visualizer class to handle brightness and color values seperately. Should not be instantiated outside of a Visualizer.
class VisualizerMapper {
    private var orderedDrivers: [VisualizationDriver] = [VeryLowSpectrumDriver(),
                                                         LowSpectrumDriver(),
                                                         MidSpectrumDriver(),
                                                         HighSpectrumDriver()]
    private var driverDict: [String : VisualizationDriver] = [:]
	private var driverIdDict: [Int : VisualizationDriver] = [:]
    
    private var driver: VisualizationDriver
    
    // private var preFilter = BiasedIIRFilter(size: 1)
	private var preFilter = SavitzkyGolayFilter(initialValue: 0.0, filterOrder: .nine)
	private var postFilter = BiasedIIRFilter(initialValue: 0.0)
	
    // The range of input values that generateMapping() remaps to the range 0-1
	var inputMin: Float = 0.0
    var inputMax: Float = 1.0
	
	// The range of values remapped to by generateMapping()
	var outputMin: Float = 0.0 {
		didSet {
			if outputMin < 0.0 { print("outputMin is less than 0!") }
		}
	}
	var outputMax: Float = 1.0 {
		didSet {
			if outputMax > 1.0 { print("outputMax is greater than 1!") }
		}
	}
    
    /// Whether to invert the input range
    var invert = false
    
    /// Whether to use a dynamic subrange on the input range
    var useDynamicRange = false {
        willSet {
            if newValue && !useDynamicRange { dynamicRange.resetRangeWithInitial(min: inputMin, max: inputMax) }
        }
    }
    
    var dynamicRange = DynamicRange()
    
	var upwardsSmoothing: Float = 0.5 {
        didSet {
            postFilter.upwardsAlpha = sqrtf(upwardsSmoothing)
        }
    }
    
	var downwardsSmoothing: Float = 0.5 {
        didSet {
            postFilter.downwardsAlpha = sqrtf(downwardsSmoothing)
        }
    }
    
    init() {
        driver = orderedDrivers[0]
        
        //preFilter.upwardsAlpha = 0.4
        //preFilter.downwardsAlpha = 0.4
		postFilter.upwardsAlpha = sqrtf(0.5)
		postFilter.downwardsAlpha = sqrtf(0.5)
        
        for driver in orderedDrivers {
            driverDict[driver.name] = driver
			driverIdDict[driver.id] = driver
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
	
	/// Gets the id of the current driver
	///
	/// - Returns: The name of the current driver
	func driverId() -> Int {
		return driver.id
	}
    
    /// Sets the current driver
    ///
    /// - Parameter name: The name of the driver to set
    func setDriver(withName name: String) {
        driver = driverDict[name] ?? orderedDrivers[0]
    }
	
	/// Sets the current driver
	///
	/// - Parameter name: The id of the driver to set
	func setDriver(withId id: Int) {
		driver = driverIdDict[id] ?? orderedDrivers[0]
	}
    
    /// Transforms the value given by the driver and sets inputVal and outputVal
    fileprivate func generateMapping(fromBuffer buffer: AudioMapper) -> VisualizerData {
		// Setup returned data
		var data = VisualizerData()
		
		var newVal = preFilter.filter(nextValue: driver.output(usingBuffer: buffer))
        newVal = postFilter.filter(nextValue: newVal)
		
		data.inputVal = newVal
		
        if useDynamicRange {
            let range = dynamicRange.calculateRange(forNextValue: newVal)
            newVal = remapValueToUnit(newVal, min: range.min, max: range.max)
            data.dynamicInputRange.min = range.min
            data.dynamicInputRange.max = range.max
		} else {
			newVal = remapValueToUnit(newVal, min: inputMin, max: inputMax)
		}
        
        if invert {
            newVal = 1.0 - newVal
        }
        
        data.outputVal = remapValueFromUnit(newVal, min: outputMin, max: outputMax)
		return data
    }
}

/// A container meant to consolidate output data from the visualizer to pass to its data delegate
struct VisualizerData {
    var inputVal: Float = 0.0
    var outputVal: Float = 0.0
    var dynamicInputRange: (min: Float, max: Float) = (0, 0)
}

/// The output delegate of a Visualizer object implements this protocol to perform specialized actions when the visualizer produces a color
protocol VisualizerDelegate: class {
    func didVisualizeIntoColor(_ color: NSColor, brightnessVal: Float, colorVal: Float)
    func didVisualizeWithData(brightnessData: VisualizerData, colorData: VisualizerData)
}
