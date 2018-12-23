/* Applies a different alpha to an IIR Filter for increasing and decreasing values */

class BiasedIIRFilter {
    
    var downwardsAlpha: Double = 0.5 {
        didSet {
            oneMinusDAlpha = 1.0 - downwardsAlpha
        }
    }
    
    var upwardsAlpha: Double = 0.5 {
        didSet {
            oneMinusUAlpha = 1.0 - upwardsAlpha
        }
    }
    
    private var oneMinusDAlpha: Double = 0.5
    private var oneMinusUAlpha: Double = 0.5
    
    private var lastData: [Double]
    
    var size: Int {
        get {
            return lastData.count
        }
    }
    
    init(size: Int) {
        lastData = Array<Double>(repeating: 0.0, count: size)
    }
    
    init(initialData: [Double]) {
        lastData = initialData
    }
    
    func applyFilter(toValue value: Double, atIndex index: Int) -> Double {
        let oldValue = lastData[index]
        var newValue = 0.0
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
    
    func applyFilter(toData data: inout [Double]) {
        assert(data.count == size)
        for i in 0..<size {
            data[i] = applyFilter(toValue: data[i], atIndex: i)
        }
    }
}
