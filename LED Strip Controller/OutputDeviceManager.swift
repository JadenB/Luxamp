//
//  OutputDeviceManager.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/25/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Foundation

class OutputDeviceManager: NSObject, ORSSerialPortDelegate {
    
    static let shared = OutputDeviceManager()
    
    var port: ORSSerialPort?
    private var delegates: [OutputDeviceDelegate] = []
    
    var isActive = false
    
    func addDelegate(_ d: OutputDeviceDelegate) {
        delegates.append(d)
    }
    
    static func getDevices() -> [String] {
        return ORSSerialPortManager.shared().availablePorts.map {$0.path}
    }
    
    func selectPort(withPath path: String) -> Bool {
        guard let newPort = ORSSerialPort(path: path) else {
            print("failed to select port with path \(path)")
            return false
        }
        
        newPort.delegate = self
        newPort.baudRate = 9600
        newPort.parity = .none
        newPort.numberOfStopBits = 1
        
        port = newPort
        
        return true
    }
    
    func sendInt(_ x: UInt32) {
        var num = x
        port?.send(Data(bytes: &num, count: MemoryLayout<UInt32>.size))
        print("sent \(MemoryLayout<UInt32>.size) bytes to \(port!.name)")
    }
    
    func sendByte(_ b: UInt8) {
        var byte = b
        port?.send(Data(bytes: &byte, count: 1))
        print("sent \(MemoryLayout<UInt8>.size) bytes to \(port!.name)")
    }
    
    func sendPacket(packet: [UInt8], size: Int) {
        var packetWithChecksum = packet
        packetWithChecksum.append(computeChecksum(fromBytes: packet))
        port?.send(Data(bytes: packetWithChecksum, count: packetWithChecksum.count))
    }
    
    private func computeChecksum(fromBytes bytes: [UInt8]) -> UInt8 {
        var checksum: UInt8 = 0
        for byte in bytes {
            checksum = checksum &+ byte
        }
        return ~checksum &+ 1
    }
    
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        delegates.forEach { $0.deviceRemoved(deviceName: serialPort.name) }
        return
    }
    
    func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        isActive = true
    }
    
    func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        isActive = false
    }
    
    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        let result = [UInt8](data)
        print("recieved \(result)")
    }
}

protocol OutputDeviceDelegate {
    func deviceRemoved(deviceName: String)
}


