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

class LightController {
    
    let refreshRate: Double
    let deviceManager = OutputDeviceManager.shared
    
    init(refreshRate: Double) {
        self.refreshRate = refreshRate
    }
    
    func turnOn() {
        
    }
    
    func turnOff() {
        
    }
    
    func setColor(color: NSColor) {
        if !deviceManager.isActive {
            return
        }
        
        guard let calibratedColor = color.usingColorSpace(NSColorSpace.deviceRGB) else {
            print("setColor() failed creating calibrated color")
            return
        }
        
        let rCom = calibratedColor.redComponent
        let gCom = calibratedColor.greenComponent
        let bCom = calibratedColor.blueComponent
        
        let r = UInt8(rCom * rCom * 255)
        let g = UInt8(gCom * gCom * 255)
        let b = UInt8(bCom * bCom * 255)
        
        let packet: [UInt8] = [COLOR_BYTE, r, g, b]
        
        deviceManager.sendPacket(packet: packet, size: PACKET_SIZE)
    }
    
}
