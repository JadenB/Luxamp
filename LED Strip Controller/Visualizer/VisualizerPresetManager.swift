//
//  VisualizerPresetManager.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/26/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

fileprivate let USERDEFAULTS_PRESETS_KEY = "presets"
let PRESETMANAGER_DEFAULT_PRESET_NAME = "Default"

class VisualizerPresetManager {
    
    let defaultP = VisualizerPreset.defaultPreset
    
    weak var visualizer: Visualizer!
    private var presets: [String : VisualizerPreset] = [:]
    private var orderedPresets: [VisualizerPreset] = []
    
    init() {
        loadPresetsFromDisk()
    }
    
    /// Attempts to load saved presets from UserDefaults, or creates the default preset if none are found
    private func loadPresetsFromDisk() {
        guard let presetData = UserDefaults.standard.object(forKey: USERDEFAULTS_PRESETS_KEY) as? Data else {
            presets = [PRESETMANAGER_DEFAULT_PRESET_NAME:VisualizerPreset.defaultPreset]
            orderedPresets = [VisualizerPreset.defaultPreset]
            return
        }
        
        do {
            let loadedPresets = try JSONDecoder().decode([VisualizerPreset].self, from: presetData)
            
            for p in loadedPresets {
                presets[p.name] = p
            }
            orderedPresets = loadedPresets
        } catch {
            print(error)
        }
    }
    
    /// Gets the names of all loaded presets
    ///
    /// - Returns: The names of loaded presets in the order they were saved
    func getPresetNames() -> [String] {
        return orderedPresets.map { $0.name }
    }
    
    /// Applies the preset with a matching name to the current visualizer
    ///
    /// - Parameter name: The name of the preset to apply. Crashes if the preset does not exist.
    func apply(name: String) {
        guard let preset = presets[name] else {
            fatalError("Preset does not exist!")
        }
        
        let brightness = visualizer.brightness
        let color = visualizer.color
        
        visualizer.gradient = preset.gradient
        
        /* BRIGHTNESS */
        brightness.setDriver(withName: preset.brightnessDriverName)
        
        brightness.inputMax = preset.brightnessRangeUpper
        brightness.inputMin = preset.brightnessRangeLower
        brightness.invert = preset.brightnessInvert
        brightness.useDynamicRange = preset.brightnessUseDynamicRange
        
        brightness.dynamicRange.useMin = preset.brightnessDynamicUseMin
        brightness.dynamicRange.useMax = preset.brightnessDynamicUseMax
        brightness.dynamicRange.aggression = preset.brightnessDynamicAggression
        
        brightness.upwardsSmoothing = preset.brightnessUpwardsSmoothing
        brightness.downwardsSmoothing = preset.brightnessDownwardsSmoothing
        
        /* COLOR */
        color.setDriver(withName: preset.colorDriverName)
        
        color.inputMax = preset.colorRangeUpper
        color.inputMin = preset.colorRangeLower
        color.invert = preset.colorInvert
        color.useDynamicRange = preset.colorUseDynamicRange
        
        color.dynamicRange.useMin = preset.colorDynamicUseMin
        color.dynamicRange.useMax = preset.colorDynamicUseMax
        color.dynamicRange.aggression = preset.colorDynamicAggression
        
        color.upwardsSmoothing = preset.colorUpwardsSmoothing
        color.downwardsSmoothing = preset.colorDownwardsSmoothing
    }
    
    /// Saves the settings of the current visualizer as a preset
    ///
    /// - Parameter name: The name that the preset should be saved as. Replaces a preset if one with the same name already exists.
    func saveCurrentSettings(name: String) {
        let brightness = visualizer.brightness
        let color = visualizer.color
        
        let newPreset = VisualizerPreset(name: name)
        
        newPreset.gradient = visualizer.gradient
        
        /* BRIGHTNESS */
        newPreset.brightnessDriverName = brightness.driverName()
        
        newPreset.brightnessRangeUpper = brightness.inputMax
        newPreset.brightnessRangeLower = brightness.inputMin
        newPreset.brightnessInvert = brightness.invert
        newPreset.brightnessUseDynamicRange = brightness.useDynamicRange
        
        newPreset.brightnessDynamicUseMax = brightness.dynamicRange.useMax
        newPreset.brightnessDynamicUseMin = brightness.dynamicRange.useMin
        newPreset.brightnessDynamicAggression = brightness.dynamicRange.aggression
        
        newPreset.brightnessUpwardsSmoothing = brightness.upwardsSmoothing
        newPreset.brightnessDownwardsSmoothing = brightness.downwardsSmoothing
        
        /* COLOR */
        newPreset.colorDriverName = color.driverName()
        
        newPreset.colorRangeUpper = color.inputMax
        newPreset.colorRangeLower = color.inputMin
        newPreset.colorInvert = color.invert
        newPreset.colorUseDynamicRange = color.useDynamicRange
        
        newPreset.colorDynamicUseMax = color.dynamicRange.useMax
        newPreset.colorDynamicUseMin = color.dynamicRange.useMin
        newPreset.colorDynamicAggression = color.dynamicRange.aggression
        
        newPreset.colorUpwardsSmoothing = color.upwardsSmoothing
        newPreset.colorDownwardsSmoothing = color.downwardsSmoothing
        
        presets[name] = newPreset
        orderedPresets.append(newPreset)
        syncToUserDefaults()
    }
    
    /// Updates the presets in UserDefaults
    private func syncToUserDefaults() {
        guard let presetData = try? JSONEncoder().encode(orderedPresets) else {
            fatalError("Failed encoding presets!")
        }
        
        UserDefaults.standard.set(presetData, forKey: USERDEFAULTS_PRESETS_KEY)
    }
    
    /// Deletes a preset
    ///
    /// - Parameter name: The name of the preset to delete
    func delete(name: String) {
        orderedPresets.removeAll() {$0.name == name}
        presets.removeValue(forKey: name)
        syncToUserDefaults()
    }
}

class VisualizerPreset: Codable {
    static let defaultPreset = VisualizerPreset(name: PRESETMANAGER_DEFAULT_PRESET_NAME)
    
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    required init(from decoder: Decoder) {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let d = VisualizerPreset.defaultPreset
            
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? d.name
            
            codableGradient = try container.decodeIfPresent(CodableGradient.self, forKey: .codableGradient) ?? d.codableGradient
            
            /* BRIGHTNESS */
            brightnessRangeUpper = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeUpper) ?? d.brightnessRangeUpper
            brightnessRangeLower = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeLower) ?? d.brightnessRangeLower
            
            brightnessDriverName = try container.decodeIfPresent(String.self, forKey: .brightnessDriverName) ?? d.brightnessDriverName
            brightnessInvert = try container.decodeIfPresent(Bool.self, forKey: .brightnessInvert) ?? d.brightnessInvert
            brightnessUseDynamicRange = try container.decodeIfPresent(Bool.self, forKey: .brightnessUseDynamicRange) ?? d.brightnessUseDynamicRange
            
            brightnessDynamicUseMax = try container.decodeIfPresent(Bool.self, forKey: .brightnessDynamicUseMax) ?? d.brightnessDynamicUseMax
            brightnessDynamicUseMin = try container.decodeIfPresent(Bool.self, forKey: .brightnessDynamicUseMin) ?? d.brightnessDynamicUseMin
            brightnessDynamicAggression = try container.decodeIfPresent(Float.self, forKey: .brightnessDynamicAggression) ?? d.brightnessDynamicAggression
            
            brightnessUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessUpwardsSmoothing) ?? d.brightnessUpwardsSmoothing
            brightnessDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessDownwardsSmoothing) ?? d.brightnessDownwardsSmoothing
            
            /* COLOR */
            colorRangeUpper = try container.decodeIfPresent(Float.self, forKey: .colorRangeUpper) ?? d.colorRangeUpper
            colorRangeLower = try container.decodeIfPresent(Float.self, forKey: .colorRangeLower) ?? d.colorRangeLower
            
            colorDriverName = try container.decodeIfPresent(String.self, forKey: .colorDriverName) ?? d.colorDriverName
            colorInvert = try container.decodeIfPresent(Bool.self, forKey: .colorInvert) ?? d.colorInvert
            colorUseDynamicRange = try container.decodeIfPresent(Bool.self, forKey: .colorUseDynamicRange) ?? d.colorUseDynamicRange
            
            colorDynamicUseMax = try container.decodeIfPresent(Bool.self, forKey: .colorDynamicUseMax) ?? d.colorDynamicUseMax
            colorDynamicUseMin = try container.decodeIfPresent(Bool.self, forKey: .colorDynamicUseMin) ?? d.colorDynamicUseMin
            colorDynamicAggression = try container.decodeIfPresent(Float.self, forKey: .colorDynamicAggression) ?? d.colorDynamicAggression
            
            colorUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .colorUpwardsSmoothing) ?? d.colorUpwardsSmoothing
            colorDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .colorDownwardsSmoothing) ?? d.colorDownwardsSmoothing
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    /* GLOBAL SETTINGS */
    fileprivate var codableGradient: CodableGradient = CodableGradient()
    var gradient: NSGradient {
        get {
            return codableGradient.gradient!
        }
        set {
            codableGradient.gradient = newValue
        }
    }
    
    /* BRIGHTNESS SETTINGS */
    var brightnessRangeUpper: Float = 1.0
    var brightnessRangeLower: Float = 0.0
    
    var brightnessDriverName: String = "Low Spectrum"
    var brightnessInvert: Bool = false
    var brightnessUseDynamicRange: Bool = false
    
    var brightnessDynamicUseMin: Bool = true
    var brightnessDynamicUseMax: Bool = true
    var brightnessDynamicAggression: Float = 0.50
    
    var brightnessUpwardsSmoothing: Float = 0.50
    var brightnessDownwardsSmoothing: Float = 0.50
    
    /* COLOR SETTINGS */
    var colorRangeUpper: Float = 1.0
    var colorRangeLower: Float = 0.0
    
    var colorDriverName: String = "Low Spectrum"
    var colorInvert: Bool = false
    var colorUseDynamicRange: Bool = false
    
    var colorDynamicUseMin: Bool = true
    var colorDynamicUseMax: Bool = true
    var colorDynamicAggression: Float = 0.50
    
    var colorUpwardsSmoothing: Float = 0.50
    var colorDownwardsSmoothing: Float = 0.50
}

/// A wrapper around NSGradient that allows it to conform to the Codable protocol
fileprivate class CodableGradient: Codable {
    var gradient = NSGradient(starting: .red, ending: .yellow)
    
    init() {}
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let gradientData = try container.decode(Data.self, forKey: .gradient)
        gradient = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSGradient.self, from: gradientData)
    }
    
    func encode(to encoder: Encoder) throws {
        let gradientData = try NSKeyedArchiver.archivedData(withRootObject: gradient!, requiringSecureCoding: false)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gradientData, forKey: .gradient)
    }
    
    enum CodingKeys: String, CodingKey {
        case gradient
    }
}
