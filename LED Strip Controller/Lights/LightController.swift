//
//  LightController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let COLOR_BYTE: UInt8 = 99 // 'c'
let POWER_BYTE: UInt8 = 112 // 'p'
let PACKET_SIZE = 5
let USERDEFAULTS_DELAY_KEY = "delay"

class LightController: DeviceManagerResponder {
    
    static let shared = LightController()
    
    private let lightSerialQueue = DispatchQueue(label: "lightSerialQueue")
    private var state: LightState = .Off
    private var ignoreDelayColorQueued = false
    private var ignoreDelayColor: NSColor = .black
    private var delayedColorsQueued: UInt = 0 {
        didSet {
            if ignoreDelayColorQueued && delayedColorsQueued == 0 {
                ignoreDelayColorQueued = false
                setColorIgnoreDelay(color: ignoreDelayColor)
            }
        }
    }
    
    /// How long to wait before sending a custom color in milliseconds
    var delay: Int = 0 {
        didSet {
            UserDefaults.standard.set(delay, forKey: USERDEFAULTS_DELAY_KEY)
        }
    }
    
    // 2.2 gamma correction to convert sRGB colors to linear for PWM color production
    private let gammaLookup: [UInt8] = [
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1,
        1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2, 2,
        3, 3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 6, 6, 6,
        6, 7, 7, 7, 8, 8, 8, 9, 9, 9, 10, 10, 11, 11, 11, 12,
        12, 13, 13, 13, 14, 14, 15, 15, 16, 16, 17, 17, 18, 18, 19, 19,
        20, 20, 21, 22, 22, 23, 23, 24, 25, 25, 26, 26, 27, 28, 28, 29,
        30, 30, 31, 32, 33, 33, 34, 35, 35, 36, 37, 38, 39, 39, 40, 41,
        42, 43, 43, 44, 45, 46, 47, 48, 49, 49, 50, 51, 52, 53, 54, 55,
        56, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71,
        73, 74, 75, 76, 77, 78, 79, 81, 82, 83, 84, 85, 87, 88, 89, 90,
        91, 93, 94, 95, 97, 98, 99, 100, 102, 103, 105, 106, 107, 109, 110, 111,
        113, 114, 116, 117, 119, 120, 121, 123, 124, 126, 127, 129, 130, 132, 133, 135,
        137, 138, 140, 141, 143, 145, 146, 148, 149, 151, 153, 154, 156, 158, 159, 161,
        163, 165, 166, 168, 170, 172, 173, 175, 177, 179, 181, 182, 184, 186, 188, 190,
        192, 194, 196, 197, 199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219, 221,
        223, 225, 227, 229, 231, 234, 236, 238, 240, 242, 244, 246, 248, 251, 253, 255 ]
    
    
    private init() {
        DeviceManager.shared.responder = self
        delay = UserDefaults.standard.integer(forKey: USERDEFAULTS_DELAY_KEY)
    }
    
    /// Turn the lights on
    func turnOn() {
        state = .On
        DeviceManager.shared.sendPacket(packet: [POWER_BYTE, 1, 0, 0], size: 4)
    }
    
    /// Turn the lights off
    func turnOff() {
        state = .Off
        sendColorToDevice(color: .black)
        DeviceManager.shared.sendPacket(packet: [POWER_BYTE, 0, 0, 0], size: 4)
    }
    
    /// The current on/off status of the lights
    func isOn() -> Bool {
        return state == .On
    }
    
    /// Sets the color of the lights. Only works if they are on
    ///
    /// - Parameter color: The color to set the lights to
    func setColor(color: NSColor) {
        if state == .On {
            if delay == 0 {
                sendColorToDevice(color: color)
            } else {
                delayedColorsQueued += 1
                lightSerialQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) {
                    self.sendColorToDevice(color: color)
                    self.delayedColorsQueued -= 1
                }
            }
        }
    }
    
    /// Sets the color of the lights ignoring the set delay. Waits until all previously set colors with delay have finished.
    ///
    /// - Parameter color: The color to set the lights to
    func setColorIgnoreDelay(color: NSColor) {
        if state == .On && delayedColorsQueued == 0 {
            sendColorToDevice(color: color)
        } else if state == .On {
            ignoreDelayColorQueued = true
            ignoreDelayColor = color
        }
    }
    
    /// Calibrates the color for the lights and sends the device a packet containing the RGB values
    ///
    /// - Parameter color: The color to send
    private func sendColorToDevice(color: NSColor) {
            guard let calibratedColor = color.usingColorSpace(NSColorSpace.genericRGB) else {
                print("setColor() failed creating calibrated color")
                return
            }
            
            let rCom = Int(calibratedColor.redComponent * 255)
            let gCom = Int(calibratedColor.greenComponent * 255)
            let bCom = Int(calibratedColor.blueComponent * 255)
            
            // for some reason squaring the values gives a more linear-appearing brightness scale
            let r = gammaLookup[rCom] //UInt8(rCom * rCom * 255)
            let g = gammaLookup[gCom] //UInt8(gCom * gCom * sqrt(gCom) * 255)
            let b = gammaLookup[bCom] //UInt8(bCom * bCom * 255)
            
            let packet: [UInt8] = [COLOR_BYTE, r, g, b]
            
            DeviceManager.shared.sendPacket(packet: packet, size: PACKET_SIZE)
    }
    
    // MARK: - DeviceManagerResponder
    
    func deviceBecameActive() {}
    
    func deviceBecameInactive() {}
    
    /// Called by DeviceManager when a color is sent to the lights while they are off
    func deviceRespondedWithOffStatus() {
        if state == .On {
            turnOn() // if the state is on but the lights are off, turn them on to get back in sync
        }
    }
}

fileprivate enum LightState {
    case On
    case Off
}
