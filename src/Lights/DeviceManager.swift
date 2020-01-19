//
//  OutputDeviceManager.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let DEVICEMANAGER_DEVICE_PATH_KEY = "devicePath"

// Manages a light controlling device over Serial I/O
class DeviceManager: NSObject, ORSSerialPortDelegate {
    
    static let shared = DeviceManager()
    
    weak var responder: DeviceManagerResponder?
    private var _port: ORSSerialPort?
    
    private override init() {
        super.init()
        if let savedPath = UserDefaults.standard.string(forKey: DEVICEMANAGER_DEVICE_PATH_KEY) {
            if getDevices().contains(savedPath) {
                let _ = selectDevice(withPath: savedPath) // assigning to dummy variable to get rid of compiler warning
                activateDevice()
            }
        }
    }
    
    /// Gets the available serial devices
    ///
    /// - Returns: The paths of all connected devices
    func getDevices() -> [String] {
        return ORSSerialPortManager.shared().availablePorts.map {$0.path}
    }
    
    /// Sets the current device to interface with
    ///
    /// - Parameter path: The path of the device
    /// - Returns: Whether the device was selected sucessfully
    func selectDevice(withPath path: String) -> Bool {
        guard let newPort = ORSSerialPort(path: path) else {
            return false
        }
        
        newPort.delegate = self
        newPort.baudRate = 9600
        newPort.parity = .none
        newPort.numberOfStopBits = 1
        
        _port = newPort
        UserDefaults.standard.set(newPort.path, forKey: DEVICEMANAGER_DEVICE_PATH_KEY)
        return true
    }
    
    /// Checks if a device is selected, even if it is not active
    ///
    /// - Returns: Whether a device is selected, even if it is not active
    func deviceIsSelected() -> Bool {
        return _port != nil
    }
    
    /// Gets the path of the current device, or an empty string if none is selected
    ///
    /// - Returns: The path of the current device, or an empty string if none is selected
    func selectedDevice() -> String {
        return _port?.path ?? ""
    }
    
    /// Checks if the current device is active
    ///
    /// - Returns: Whether the device is active or false if there is no device
    func deviceIsActive() -> Bool {
        return _port?.isOpen ?? false
    }
    
    /// Attempts to activate the current device
    func activateDevice() {
        _port?.open()
    }
    
    /// Deactivates the current device
    func deactivateDevice() {
        _port?.close()
    }
    
    /// Sends a packet with a checksum appended to the currently selected device if it is active.
    ///
    /// - Parameters:
    ///   - packet: The array of bytes to send
    ///   - size: The number of bytes to send
    func sendPacket(packet: [UInt8]) {
        if deviceIsActive() {
            var packetWithChecksum = packet
            packetWithChecksum.append(computeChecksum(fromBytes: packet))
            _port?.send(Data(bytes: packetWithChecksum, count: packetWithChecksum.count))
        }
    }
    
    /// Computes the checksum for the given bytes
    ///
    /// - Parameter bytes: The bytes to use in the computation
    /// - Returns: The computed checksum
    private func computeChecksum(fromBytes bytes: [UInt8]) -> UInt8 {
        var checksum: UInt8 = 0
        for byte in bytes {
            checksum = checksum &+ byte
        }
        return ~checksum &+ 1
    }
    
    /// Called by the port when it is removed
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        responder?.deviceBecameInactive()
        _port = nil
    }
    
    /// Called by the port when it is opened sucessfully
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        responder?.deviceBecameActive()
    }
    
    /// Called by the port when it is closed
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        responder?.deviceBecameInactive()
    }
    
    /// Called by the port when it recieves data
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        if data.first == 0 {
            responder?.deviceRespondedWithOffStatus()
        }
    }
}

/// The responder of the DeviceManager object implements this protocol to perform specialized actions when a device becomes active or inactive
protocol DeviceManagerResponder: class {
    func deviceBecameActive()
    func deviceBecameInactive()
    func deviceRespondedWithOffStatus()
}


