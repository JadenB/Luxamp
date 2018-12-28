//
//  VisualizerPresetManager.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/26/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

fileprivate let USERDEFAULTS_PRESETS_KEY = "presets"

class VisualizerPresetManager {
    
    var visualizer: Visualizer
    var presets: [String : VisualizerPreset] = [:]
    private var orderedPresets: [VisualizerPreset] = []
    
    init(withVisualizer v: Visualizer) {
        visualizer = v
        loadPresets()
    }
    
    func loadPresets() {
        guard let presetData = UserDefaults.standard.object(forKey: USERDEFAULTS_PRESETS_KEY) as? Data else {
            presets = ["Default":VisualizerPreset.defaultPreset]
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
    
    func getPresetNames() -> [String] {
        return orderedPresets.map { $0.name }
    }
    
    func applyPreset(name: String) {
        guard let preset = presets[name] else {
            fatalError("Preset does not exist!")
        }
        
        let brightness = visualizer.brightness
        let hue = visualizer.hue
        
        visualizer.setBrightnessDriver(name: preset.brightnessDriverName)
        visualizer.setHueDriver(name: preset.hueDriverName)
        
        visualizer.useGradient = preset.useGradient
        visualizer.gradient = preset.gradient
        
        brightness.max = preset.brightnessRangeUpper
        brightness.min = preset.brightnessRangeLower
        brightness.invert = preset.brightnessInvert
        brightness.useAdaptiveRange = preset.brightnessAdaptive
        
        brightness.upwardsSmoothing = preset.brightnessUpwardsSmoothing
        brightness.downwardsSmoothing = preset.brightnessDownwardsSmoothing
        
        hue.max = preset.hueRangeUpper
        hue.min = preset.hueRangeLower
        hue.invert = preset.hueInvert
        hue.useAdaptiveRange = preset.hueAdaptive
        
        hue.upwardsSmoothing = preset.hueUpwardsSmoothing
        hue.downwardsSmoothing = preset.hueDownwardsSmoothing
    }
    
    func saveCurrentStateAsPreset(name: String) {
        let brightness = visualizer.brightness
        let hue = visualizer.hue
        
        let newPreset = VisualizerPreset(name: name)
        
        newPreset.brightnessDriverName = brightness.driver.name
        newPreset.hueDriverName = hue.driver.name
        
        newPreset.useGradient = visualizer.useGradient
        newPreset.gradient = visualizer.gradient
        
        newPreset.brightnessRangeUpper = brightness.max
        newPreset.brightnessRangeLower = brightness.min
        newPreset.brightnessInvert = brightness.invert
        newPreset.brightnessAdaptive = brightness.useAdaptiveRange
        
        newPreset.brightnessUpwardsSmoothing = brightness.upwardsSmoothing
        newPreset.brightnessDownwardsSmoothing = brightness.downwardsSmoothing
        
        newPreset.hueRangeUpper = hue.max
        newPreset.hueRangeLower = hue.min
        newPreset.hueInvert = hue.invert
        newPreset.hueAdaptive = hue.useAdaptiveRange
        
        newPreset.hueUpwardsSmoothing = hue.upwardsSmoothing
        newPreset.hueDownwardsSmoothing = hue.downwardsSmoothing
        
        presets[name] = newPreset
        orderedPresets.append(newPreset)
        savePresetsToUserDefaults()
    }
    
    func savePresetsToUserDefaults() {
        guard let presetData = try? JSONEncoder().encode(orderedPresets) else {
            fatalError("Failed encoding presets!")
        }
        
        UserDefaults.standard.set(presetData, forKey: USERDEFAULTS_PRESETS_KEY)
    }
    
    func deletePreset(name: String) {
        orderedPresets.removeAll() {$0.name == name}
        presets.removeValue(forKey: name)
        savePresetsToUserDefaults()
    }
}

class VisualizerPreset: Codable {
    static let defaultPreset = VisualizerPreset(name: "Default")
    
    var name: String
    
    init(name: String) {
        self.name = name
    }
    
    required init(from decoder: Decoder) {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name) ?? VisualizerPreset.defaultPreset.name
            
            useGradient = try container.decodeIfPresent(Bool.self, forKey: .useGradient) ?? VisualizerPreset.defaultPreset.useGradient
            codableGradient = try container.decodeIfPresent(CodableGradient.self, forKey: .codableGradient) ?? VisualizerPreset.defaultPreset.codableGradient
            
            brightnessRangeUpper = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeUpper) ?? VisualizerPreset.defaultPreset.brightnessRangeUpper
            brightnessRangeLower = try container.decodeIfPresent(Float.self, forKey: .brightnessRangeLower) ?? VisualizerPreset.defaultPreset.brightnessRangeLower
            
            brightnessDriverName = try container.decodeIfPresent(String.self, forKey: .brightnessDriverName) ?? VisualizerPreset.defaultPreset.brightnessDriverName
            brightnessInvert = try container.decodeIfPresent(Bool.self, forKey: .brightnessInvert) ?? VisualizerPreset.defaultPreset.brightnessInvert
            brightnessAdaptive = try container.decodeIfPresent(Bool.self, forKey: .brightnessAdaptive) ?? VisualizerPreset.defaultPreset.brightnessAdaptive
            
            brightnessUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessUpwardsSmoothing) ?? VisualizerPreset.defaultPreset.brightnessUpwardsSmoothing
            brightnessDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .brightnessDownwardsSmoothing) ?? VisualizerPreset.defaultPreset.brightnessDownwardsSmoothing
            
            hueRangeUpper = try container.decodeIfPresent(Float.self, forKey: .hueRangeUpper) ?? VisualizerPreset.defaultPreset.hueRangeUpper
            hueRangeLower = try container.decodeIfPresent(Float.self, forKey: .hueRangeLower) ?? VisualizerPreset.defaultPreset.hueRangeLower
            
            hueDriverName = try container.decodeIfPresent(String.self, forKey: .hueDriverName) ?? VisualizerPreset.defaultPreset.hueDriverName
            hueInvert = try container.decodeIfPresent(Bool.self, forKey: .hueInvert) ?? VisualizerPreset.defaultPreset.hueInvert
            hueAdaptive = try container.decodeIfPresent(Bool.self, forKey: .hueAdaptive) ?? VisualizerPreset.defaultPreset.hueAdaptive
            
            hueUpwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .hueUpwardsSmoothing) ?? VisualizerPreset.defaultPreset.hueUpwardsSmoothing
            hueDownwardsSmoothing = try container.decodeIfPresent(Float.self, forKey: .hueDownwardsSmoothing) ?? VisualizerPreset.defaultPreset.hueDownwardsSmoothing
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    var useGradient: Bool = true
    var gradient: NSGradient {
        get {
            return codableGradient.gradient!
        }
        set {
            codableGradient.gradient = newValue
        }
    }
    fileprivate var codableGradient: CodableGradient = CodableGradient()
    
    /* BRIGHTNESS SETTINGS */
    var brightnessRangeUpper: Float = 1.0
    var brightnessRangeLower: Float = 0.0
    
    var brightnessDriverName: String = "Low Spectrum"
    var brightnessInvert: Bool = false
    var brightnessAdaptive: Bool = false
    
    var brightnessUpwardsSmoothing: Float = 0.50
    var brightnessDownwardsSmoothing: Float = 0.50
    
    /* COLOR SETTINGS */
    var hueRangeUpper: Float = 1.0
    var hueRangeLower: Float = 0.0
    
    var hueDriverName: String = "Low Spectrum"
    var hueInvert: Bool = false
    var hueAdaptive: Bool = false
    
    var hueUpwardsSmoothing: Float = 0.50
    var hueDownwardsSmoothing: Float = 0.50
}

class CodableGradient: Codable {
    var gradient = NSGradient(starting: .red, ending: .yellow)
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let gradientData = try container.decode(Data.self, forKey: .gradient)
        gradient = try NSKeyedUnarchiver.unarchivedObject(ofClass: NSGradient.self, from: gradientData)
    }
    
    init() {}
    
    func encode(to encoder: Encoder) throws {
        let gradientData = try NSKeyedArchiver.archivedData(withRootObject: gradient!, requiringSecureCoding: false)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(gradientData, forKey: .gradient)
    }
    
    enum CodingKeys: String, CodingKey {
        case gradient
    }
}
