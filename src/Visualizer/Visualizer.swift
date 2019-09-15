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
    weak var delegate: VisualizerDelegate?
    
    var presets: VisualizerPresetManager
    
    var color: VisualizerMapper
    var brightness: VisualizerMapper
    
    /// The gradient used to map the output color
    var gradient: NSGradient! = NSGradient(starting: .red, ending: .yellow)
    /// Whether to gradually shift the overall hue over time
    var useEvolvingColor = false
    /// The amount to change the color every time visualize() is called
    var evolvingColorRate: Float {
        get {
            return Float(cgEvolvingColorRate)
        }
        set {
            cgEvolvingColorRate = CGFloat(newValue) // setting a CGFloat version of this variable to avoid converting types each run
        }
    }
    private var cgEvolvingColorRate: CGFloat = 0.3
    private var evolvingColorOffset: CGFloat = 0.0
    private var lastColorVal: Float = 0.0
    
    /// Initializes a Visualizer
    ///
    /// - Parameter engine: The AudioEngine to draw values from. Will be accessed each time visualize() is called.
    init(withEngine engine: AudioEngine) {
        color = VisualizerMapper(withEngine: engine)
        brightness = VisualizerMapper(withEngine: engine)
		presets = VisualizerPresetManager()
        presets.visualizer = self
        presets.apply(name: PRESETMANAGER_DEFAULT_PRESET_NAME)
    }
    
    /// Produces a color and sends it to the output delegate. Also sends raw brightness and color values to the data delegate.
    func visualize() {
        // Setup components of color
        var outputBrightness: CGFloat = 1.0
        var outputSaturation: CGFloat = 1.0
        var outputHue: CGFloat = 1.0
        
        // Calculate raw values from brightness and color mappers
        let brightnessData = brightness.applyMapping()
        let colorData = color.applyMapping()
        
        // Convert raw color mapping to hue and saturation with the gradient
        let gradientColor = gradient.interpolatedColor(atLocation: CGFloat(colorData.outputVal))
        
        // Set the final color components, ignoring brightness of gradient
        outputBrightness = CGFloat(brightnessData.outputVal)
        outputSaturation = gradientColor.saturationComponent
        outputHue = gradientColor.hueComponent
        
        if useEvolvingColor {
            let colorDiff = colorData.outputVal - lastColorVal
            if colorDiff > 0.0 {
                evolvingColorOffset += CGFloat(colorDiff) * cgEvolvingColorRate * (1/7)
            }
            
            outputHue += evolvingColorOffset
            
            if outputHue > 1.0 {
                outputHue = outputHue.truncatingRemainder(dividingBy: 1.0)
            }
            
            lastColorVal = colorData.outputVal // save the last value so the difference can be computed for the next cycle
        }
        
        // Send the computed color and associated data to the delegate
        let colorToOutput = NSColor(hue: outputHue, saturation: outputSaturation, brightness: outputBrightness, alpha: 1.0)
        delegate?.didVisualizeIntoColor(colorToOutput, brightnessVal: brightnessData.outputVal, colorVal: colorData.outputVal)
        delegate?.didVisualizeWithData(brightnessData: brightnessData, colorData: colorData)
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
	private var driverIdDict: [Int : VisualizationDriver] = [:]
    
    private var driver: VisualizationDriver
    private var engine: AudioEngine
    
    private var preFilter = BiasedIIRFilter(size: 1)
    private var postFilter = BiasedIIRFilter(size: 1)
	
    // The range of input values that applyMapping() remaps to the range 0-1
	var inputMin: Float = 0.0
    var inputMax: Float = 1.0
	
	// The range of values remapped to by applyMapping()
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
    fileprivate func applyMapping() -> VisualizerData {
		// Setup returned data
		var data = VisualizerData()
		
        var newVal = preFilter.applyFilter(toValue: driver.output(usingEngine: engine), atIndex: 0)
        newVal = postFilter.applyFilter(toValue: newVal, atIndex: 0)
		
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
