import UIKit

let LENGTH = 50
let SCALE: Float = 0.6

print("let regSine: [CGFloat] = [ ", terminator: "")
var sine: [Float] = [Float](repeating: 0.0, count: LENGTH)
for i in 0..<LENGTH {
    if i % 10 == 0 { print("") }
    sine[i] = sin(2 * Float.pi * Float(i) / Float(LENGTH))
    let s = String(format: "%.2f", sine[i] * SCALE * 0.75 / 2 + 0.5)
    print(s + (i == LENGTH - 1 ? " " : ", ") , terminator: "")
}
print("]")

var noise = [Float](repeating: 0.0, count: LENGTH)
for i in 0..<LENGTH {
    noise[i] = sine[i] * Float(arc4random()) / Float(UInt32.max)
}


print("let noisySine: [CGFloat] = [ ", terminator: "")
let smoothing: Float = 0.0
for i in 0..<LENGTH {
    if i % 10 == 0 { print("") }
    sine[i] * smoothing + noise[i] * (1 - smoothing)
    let s = String(format: "%.2f", (sine[i] * smoothing + noise[i] * (1 - smoothing)) * SCALE / 2 + 0.5)
    print(s + (i == LENGTH - 1 ? " " : ", ") , terminator: "")
}

print("]")
