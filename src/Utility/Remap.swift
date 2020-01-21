import Foundation


/// Remaps a value from the range min-max to the range 0-1
func remapValueToUnit<T : BinaryFloatingPoint>(_ value: T, min: T, max: T) -> T {
    if value >= max {
        return 1.0
    } else if value <= min {
        return 0.0
    }
    
    let scalingFactor = 1 / (max - min)
    return (value - min) * scalingFactor
}

/// Remaps a value from the range 0-1 to the range min-max
func remapValueFromUnit<T : BinaryFloatingPoint>(_ value: T, min: T, max: T) -> T {
	if value >= 1.0 {
		return max
	} else if value <= 0.0 {
		return min
	}
	let scalingFactor = max - min
	return min + (value * scalingFactor)
}

/// Remaps a value from the range min-max to the range 0-1
func remapValueToBounds<T : BinaryFloatingPoint>(_ value: T, inputMin: T, inputMax: T, outputMin: T, outputMax: T) -> T {
    if value >= inputMax {
        return outputMax
    } else if value <= inputMin {
        return outputMin
    }
    let scalingFactor = (outputMax - outputMin) / (inputMax - inputMin)
    return outputMin + (value - inputMin) * scalingFactor
}

/// Clips a value to the range min-max
func clipToBounds<T: Comparable>(_ value: T, min: T, max: T) -> T {
	if value >= max {
		return max
	} else if value <= min {
		return min
	} else {
		return value
	}
}
