/* Applies a different alpha to an IIR Filter for increasing and decreasing values */

class BiasedIIRFilter {
    
    var downwardsAlpha: Float = 0.5 {
        didSet {
            oneMinusDAlpha = 1.0 - downwardsAlpha
        }
    }
    
    var upwardsAlpha: Float = 0.5 {
        didSet {
            oneMinusUAlpha = 1.0 - upwardsAlpha
        }
    }
    
    private var oneMinusDAlpha: Float = 0.5
    private var oneMinusUAlpha: Float = 0.5
    
    private var lastData: [Float]
    
    var size: Int {
        get {
            return lastData.count
        }
    }
    
    init(size: Int) {
        lastData = Array<Float>(repeating: 0.0, count: size)
    }
    
    init(initialData: [Float]) {
        lastData = initialData
    }
    
    func applyFilter(toValue value: Float, atIndex index: Int) -> Float {
        let oldValue = lastData[index]
        var newValue: Float = 0.0
        if value == oldValue {
            return value
        } else if value > oldValue {
            newValue = upwardsAlpha * oldValue + oneMinusUAlpha * value
            lastData[index] = newValue
        } else {
            newValue = downwardsAlpha * oldValue + oneMinusDAlpha * value
            lastData[index] = newValue
        }
        return newValue
    }
    
    func applyFilter(toData data: inout [Float]) {
        assert(data.count == size)
        for i in 0..<size {
            data[i] = applyFilter(toValue: data[i], atIndex: i)
        }
    }
}
