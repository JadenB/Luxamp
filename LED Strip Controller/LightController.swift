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
            guard let calibratedColor = color.usingColorSpace(NSColorSpace.deviceRGB) else {
                print("setColor() failed creating calibrated color")
                return
            }
            
            let rCom = calibratedColor.redComponent
            let gCom = calibratedColor.greenComponent
            let bCom = calibratedColor.blueComponent
            
            // for some reason squaring the values gives a more linear-appearing brightness scale
            let r = UInt8(rCom * rCom * 255)
            let g = UInt8(gCom * gCom * sqrt(gCom) * 255)
            let b = UInt8(bCom * bCom * 255)
            
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
