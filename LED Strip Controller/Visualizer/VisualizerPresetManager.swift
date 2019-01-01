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
    
    var visualizer: Visualizer
    private var _presets: [String : VisualizerPreset] = [:]
    private var _orderedPresets: [VisualizerPreset] = []
    
    init(withVisualizer v: Visualizer) {
        visualizer = v
        loadPresets()
    }
    
    /// Attempts to load saved presets from UserDefaults, or creates the default preset if none are found
    func loadPresets() {
        guard let presetData = UserDefaults.standard.object(forKey: USERDEFAULTS_PRESETS_KEY) as? Data else {
            _presets = [PRESETMANAGER_DEFAULT_PRESET_NAME:VisualizerPreset.defaultPreset]
            _orderedPresets = [VisualizerPreset.defaultPreset]
            return
        }
        
        do {
            let loadedPresets = try JSONDecoder().decode([VisualizerPreset].self, from: presetData)
            
            for p in loadedPresets {
                _presets[p.name] = p
            }
            _orderedPresets = loadedPresets
        } catch {
            print(error)
        }
    }
    
    /// Gets the names of all loaded presets
    ///
    /// - Returns: The names of loaded presets in the order they were saved
    func getPresetNames() -> [String] {
        return _orderedPresets.map { $0.name }
    }
    
    /// Applies the preset with a matching name to the current visualizer
    ///
    /// - Parameter name: The name of the preset to apply. Crashes if the preset does not exist.
    func applyPreset(name: String) {
        guard let preset = _presets[name] else {
            fatalError("Preset does not exist!")
        }
        
        let brightness = visualizer.brightness
        let color = visualizer.color
        
        visualizer.brightness.setDriver(withName: preset.brightnessDriverName)
        visualizer.color.setDriver(withName: preset.colorDriverName)
        
        // NOTE: Currently brightness and color use the same dynamic range settings
        visualizer.gradient = preset.gradient
        visualizer.brightness.dynamicRange.aggression = preset.dynamicRangeAggression
        visualizer.color.dynamicRange.aggression = preset.dynamicRangeAggression
        visualizer.brightness.useDynamicMax = preset.useDynamicMax
        visualizer.color.useDynamicMax = preset.useDynamicMax
        visualizer.brightness.useDynamicMin = preset.useDynamicMin
        visualizer.color.useDynamicMin = preset.useDynamicMin
        
        brightness.inputMax = preset.brightnessRangeUpper
        brightness.inputMin = preset.brightnessRangeLower
        brightness.invert = preset.brightnessInvert
        brightness.useDynamicRange = preset.brightnessUseDynamicRange
        
        brightness.upwardsSmoothing = preset.brightnessUpwardsSmoothing
        brightness.downwardsSmoothing = preset.brightnessDownwardsSmoothing
        
        color.inputMax = preset.colorRangeUpper
        color.inputMin = preset.colorRangeLower
        color.invert = preset.colorInvert
        color.useDynamicRange = preset.colorUseDynamicRange
        
        color.upwardsSmoothing = preset.colorUpwardsSmoothing
        color.downwardsSmoothing = preset.colorDownwardsSmoothing
    }
    
    /// Saves the settings of the current visualizer as a preset
    ///
    /// - Parameter name: The name that the preset should be saved as. Replaces a preset if one with the same name already exists.
    func saveCurrentStateAsPreset(name: String) {
        let brightness = visualizer.brightness
        let color = visualizer.color
        
        let newPreset = VisualizerPreset(name: name)
        
        newPreset.brightnessDriverName = brightness.driverName()
        newPreset.colorDriverName = color.driverName()
        
        newPreset.gradient = visualizer.gradient
        newPreset.dynamicRangeAggression = visualizer.brightness.dynamicRange.aggression
        newPreset.useDynamicMax = visualizer.brightness.useDynamicMax
        newPreset.useDynamicMin = visualizer.brightness.useDynamicMin
        
        newPreset.brightnessRangeUpper = brightness.inputMax
        newPreset.brightnessRangeLower = brightness.inputMin
        newPreset.brightnessInvert = brightness.invert
        newPreset.brightnessUseDynamicRange = brightness.useDynamicRange
        
        newPreset.brightnessUpwardsSmoothing = brightness.upwardsSmoothing
        newPreset.brightnessDownwardsSmoothing = brightness.downwardsSmoothing
        
        newPreset.colorRangeUpper = color.inputMax
        newPreset.colorRangeLower = color.inputMin
        newPreset.colorInvert = color.invert
        newPreset.colorUseDynamicRange = color.useDynamicRange
        
        newPreset.colorUpwardsSmoothing = color.upwardsSmoothing
        newPreset.colorDownwardsSmoothing = color.downwardsSmoothing
        
        _presets[name] = newPreset
        _orderedPresets.append(newPreset)
        syncPresetsToUserDefaults()
    }
    
    /// Updates the presets in UserDefaults
    private func syncPresetsToUserDefaults() {
        guard let presetData = try? JSONEncoder().encode(_orderedPresets) else {
            fatalError("Failed encoding presets!")
        }
        
        UserDefaults.standard.set(presetData, forKey: USERDEFAULTS_PRESETS_KEY)
    }
    
    /// Deletes a preset
    ///
    /// - Parameter name: The name of the preset to delete
    func deletePreset(name: String) {
        _orderedPresets.removeAll() {$0.name == name}
        _presets.removeValue(forKey: name)
        syncPresetsToUserDefaults()
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
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? VisualizerPreset.defaultPreset.name
            
            codableGradient = try container.decodeIfPresent(CodableGradient.self, forKey: .codableGradient) ?? VisualizerPreset.defaultPreset.codableGradient
            dynamicRangeAggression = try container.decodeIfPresent(Float.self, forKey: .dynamicRangeAggression) ?? VisualizerPreset.defaultPreset.dynamicRangeAggression
            useDynamicMin = try container.decodeIfPresent(Bool.self, forKey: .useDynamicMin) ?? VisualizerPreset.defaultPreset.useDynamicMin
            useDynamicMax = try container.decodeIfPresent(Bool.self, forKey: .useDynamicMax) ?? VisualizerPreset.defaultPreset.useDynamicMax
            
            brightnessRangeUpper = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeUpper) ?? VisualizerPreset.defaultPreset.brightnessRangeUpper
            brightnessRangeLower = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeLower) ?? VisualizerPreset.defaultPreset.brightnessRangeLower
            
            brightnessDriverName = try container.decodeIfPresent(String.self, forKey: .brightnessDriverName) ?? VisualizerPreset.defaultPreset.brightnessDriverName
            brightnessInvert = try container.decodeIfPresent(Bool.self, forKey: .brightnessInvert) ?? VisualizerPreset.defaultPreset.brightnessInvert
            brightnessUseDynamicRange = try container.decodeIfPresent(Bool.self, forKey: .brightnessUseDynamicRange) ?? VisualizerPreset.defaultPreset.brightnessUseDynamicRange
            
            brightnessUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessUpwardsSmoothing) ?? VisualizerPreset.defaultPreset.brightnessUpwardsSmoothing
            brightnessDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessDownwardsSmoothing) ?? VisualizerPreset.defaultPreset.brightnessDownwardsSmoothing
            
            colorRangeUpper = try container.decodeIfPresent(Float.self, forKey: .colorRangeUpper) ?? VisualizerPreset.defaultPreset.colorRangeUpper
            colorRangeLower = try container.decodeIfPresent(Float.self, forKey: .colorRangeLower) ?? VisualizerPreset.defaultPreset.colorRangeLower
            
            colorDriverName = try container.decodeIfPresent(String.self, forKey: .colorDriverName) ?? VisualizerPreset.defaultPreset.colorDriverName
            colorInvert = try container.decodeIfPresent(Bool.self, forKey: .colorInvert) ?? VisualizerPreset.defaultPreset.colorInvert
            colorUseDynamicRange = try container.decodeIfPresent(Bool.self, forKey: .colorUseDynamicRange) ?? VisualizerPreset.defaultPreset.colorUseDynamicRange
            
            colorUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .colorUpwardsSmoothing) ?? VisualizerPreset.defaultPreset.colorUpwardsSmoothing
            colorDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .colorDownwardsSmoothing) ?? VisualizerPreset.defaultPreset.colorDownwardsSmoothing
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
    var dynamicRangeAggression: Float = 0.50
    var useDynamicMin: Bool = true
    var useDynamicMax: Bool = true
    
    /* BRIGHTNESS SETTINGS */
    var brightnessRangeUpper: Float = 1.0
    var brightnessRangeLower: Float = 0.0
    
    var brightnessDriverName: String = "Low Spectrum"
    var brightnessInvert: Bool = false
    var brightnessUseDynamicRange: Bool = false
    
    var brightnessUpwardsSmoothing: Float = 0.50
    var brightnessDownwardsSmoothing: Float = 0.50
    
    /* COLOR SETTINGS */
    var colorRangeUpper: Float = 1.0
    var colorRangeLower: Float = 0.0
    
    var colorDriverName: String = "Low Spectrum"
    var colorInvert: Bool = false
    var colorUseDynamicRange: Bool = false
    
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
