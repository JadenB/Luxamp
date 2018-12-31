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

class LightController: DeviceManagerResponder {
    
    static let shared = LightController()
    /// How long to wait before sending a color in milliseconds
    var delay: Int = 0
    
    private let patternRefreshRate: Double = 0.0 // The rate at which the current pattern calls setColor()
    private var _mode: LightMode = .Pattern
    private var _pattern: LightPattern = .Constant
    private var _state: LightState = .Off
    
    private let lightSerialQueue = DispatchQueue(label: "lightSerialQueue")
    
    var pattern: LightPattern {
        get {
            return _pattern
        }
        set {
            _pattern = newValue // TODO: implement switching patterns
        }
    }
    
    var mode: LightMode {
        get {
            return _mode
        }
        set {
            _mode = newValue // TODO: implement switching modes
        }
    }
    
    private init() {
        DeviceManager.shared.responder = self
    }
    
    /// Turn the lights on
    func turnOn() {
        _state = .On
        DeviceManager.shared.sendPacket(packet: [POWER_BYTE, 1, 0, 0], size: 4)
    }
    
    /// Turn the lights off
    func turnOff() {
        _state = .Off
        sendColorToDevice(color: .black)
        DeviceManager.shared.sendPacket(packet: [POWER_BYTE, 0, 0, 0], size: 4)
    }
    
    /// The current on/off status of the lights
    func isOn() -> Bool {
        return _state == .On
    }
    
    /// Sets the color of the lights. Only works if they are on
    ///
    /// - Parameter color: The color to set the lights to
    func setColor(color: NSColor) {
        if _state == .On {
            if delay == 0 {
                sendColorToDevice(color: color)
            } else {
                lightSerialQueue.asyncAfter(deadline: .now() + .milliseconds(delay)) { self.sendColorToDevice(color: color) }
            }
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
    
    func deviceBecameActive() {}
    
    func deviceBecameInactive() {}
    
    /// Called by DeviceManager when a color is sent to the lights while they are off
    func deviceRespondedWithOffStatus() {
        if _state == .On {
            turnOn() // if the state is on but the lights are off, turn them on to get back in sync
        }
    }
}

fileprivate enum LightState {
    case On
    case Off
}

enum LightMode: Int {
    case Pattern = 0
    case Music = 1
}

enum LightPattern {
    case Constant
    case Strobe
    case Fade
    case Jump
    case Candle
}
