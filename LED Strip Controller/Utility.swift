import Foundation

/// Remaps a value from the range min-max to the range 0-1
func remapValueToBounds(_ value: Float, min: Float, max: Float) -> Float {
    if value > max {
        return 1.0
    } else if value < min {
        return 0.0
    }
    let scalingFactor = 1 / (max - min)
    return (value - min) * scalingFactor
}

/// Remaps a value from the range min-max to the range 0-1
func remapValueToBounds(_ value: Float, inputMin: Float, inputMax: Float, outputMin: Float, outputMax: Float) -> Float {
    if value >= inputMax {
        return outputMax
    } else if value <= inputMin {
        return outputMin
    }
    let scalingFactor = (outputMax - outputMin) / (inputMax - inputMin)
    return outputMin + (value - inputMin) * scalingFactor
}
