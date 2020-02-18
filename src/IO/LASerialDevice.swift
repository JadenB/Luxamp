//
//  LASerialDevice.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/29/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

/*
Note: Consult specific device for correct N value (number of data channels)
Note: Checksum operates on all bytes between the start delimiter and itself

Packet structure:
|start delimiter| 1 byte
|opcode| 1 byte
|data| N bytes
|checksum| 1 byte
|end delimiter| 1 byte

Write channels packet structure:
|start delimiter| 1 byte
|write channels opcode| 1 byte
|channel 1 value| 1 byte
|channel 2 value| 1 byte
...
|channel N value| 1 byte
|checksum| 1 byte
|end delimiter| 1 byte

Request packet structure:
|start delimiter| 1 byte
|request opcode| 1 byte
|request type| 1 byte
|request parameters (request type dependant)| N-1 bytes
|checksum| 1 byte
|end delimiter| 1 byte

Response structure:
|start delimiter| 1 byte
|request type| 1 byte
|response code| 1 byte
|checksum| 1 byte
|end delimiter| 1 byte
*/

import Foundation
import ORSSerial
import os


fileprivate let PACKET_START_BYTE: UInt8 = 0xE7
fileprivate let PACKET_END_BYTE: UInt8 = 0x7E

fileprivate let REQUEST_OPCODE: UInt8 = 0x3F // '?'
fileprivate let WRITE_CHANNELS_OPCODE: UInt8 = 0x57 // 'W'

fileprivate let READY_REQUEST_TYPE: UInt8 = 0x72 // 'r'

fileprivate let REQUEST_RESPONSE_LENGTH = 5
fileprivate let REQUEST_TIMEOUT = 1.0
fileprivate let MAX_CONNECTION_RETRIES = 4


protocol LASerialDeviceDelegate: class {
	
}


class LASerialDevice: NSObject, ORSSerialPortDelegate {
	let channelCount: Int
	
	private let OPCODE_INDEX = 1
	private let FIRST_CHANNEL_INDEX = 2
	
	// Serial port
	private var _serialPort: ORSSerialPort?
	private var serialDeviceIsReady = false {
		didSet {
			if serialDeviceIsReady && _channelSendPacketHasBeenWrittenOnce {
				_serialPort?.send(_channelSendPacket)
			}
		}
	}
	
	// precomputed utility variables
	private let _checksumIndexInPacket: Int
	private let _packetSize: Int
	
	// channel send data
	private var _channelSendPacket = Data()
	private var _channelSendStarted = false
	private var _channelSendPacketHasBeenWrittenOnce = false
	
	// Request data
	private var _readyRequestRetries = 0
	
	init(channelCount: Int) {
		if channelCount < 0 {
			fatalError("channelCount must be positive")
		}
		
		self.channelCount = channelCount
		
		_packetSize = channelCount + 4
		_checksumIndexInPacket = _packetSize - 2
		
		super.init()
		
		_channelSendPacket = formPacket(opCode: WRITE_CHANNELS_OPCODE)
	}
	
	deinit {
		closeAndClearSerialPort()
	}
	
	// MARK: - Public Functions
	
	func connectToDevice(withPath path: String) {
		guard let newPort = ORSSerialPort(path: path) else {
			print("Failed to open port: \(path)")
			return
		}
		
		newPort.delegate = self
		newPort.baudRate = 57600
		newPort.parity = .none
		newPort.numberOfStopBits = 1
		
		closeAndClearSerialPort()
		
		_serialPort = newPort
		_serialPort!.open()
	}
	
	func disconnectFromDevice() {
		closeAndClearSerialPort()
	}
	
	func startChannelSend() {
		if _channelSendStarted {
			fatalError("Attempted to start channel send without ending previous channel send")
		}
		
		_channelSendStarted = true
	}
	
	func sendChannel(channel: Int, value: UInt8) {
		if !_channelSendStarted {
			fatalError("Attempted to send channel without starting a channel send")
		}
		
		_channelSendPacket[FIRST_CHANNEL_INDEX+channel] = value
	}
	
	func endChannelSend() {
		if !_channelSendStarted {
			fatalError("Attempted to end channel send without starting one")
		}
		
		writeChecksum(toPacket: &_channelSendPacket)

		_channelSendStarted = false
		_channelSendPacketHasBeenWrittenOnce = true
		
		if (serialDeviceIsReady) {
			_serialPort?.send(_channelSendPacket)
		}
	}
	
	// MARK: - Private Functions
	
	private func closeAndClearSerialPort() {
		_serialPort?.close()
		_serialPort?.delegate = nil
		_serialPort = nil
	}
	
	private func formPacket(opCode: UInt8) -> Data {
		// start with zeroed out channels
		var dataPacket = Data(count: _packetSize)
		
		// write header and footer
		dataPacket[0] = PACKET_START_BYTE
		dataPacket[dataPacket.count-1] = PACKET_END_BYTE
		
		// write opcode
		dataPacket[OPCODE_INDEX] = opCode
		
		return dataPacket
	}
	
	private func writeChecksum(toPacket packet: inout Data) {
		var checksum: UInt8 = 0
		
		for i in OPCODE_INDEX..<_checksumIndexInPacket {
			checksum = checksum &+ packet[i]
		}
		
		packet[_checksumIndexInPacket] = checksum
	}
	
	static private func validateResponse(forPacket responsePacket: Data, requestType: UInt8) -> Bool {
		// check that the response is for the correct request type
		if responsePacket[1] != requestType {
			return false
		}
		
		var checksum: UInt8 = 0
		for i in 1..<REQUEST_RESPONSE_LENGTH-2 {
			checksum = checksum &+ responsePacket[i]
		}
		
		return checksum == responsePacket[REQUEST_RESPONSE_LENGTH-2]
	}
	
	private func sendRequest(requestType: UInt8, timeout: TimeInterval) {
		if _serialPort == nil {
			fatalError("Cannot send request using nil port")
		}
		
		var requestPacket = formPacket(opCode: REQUEST_OPCODE)
		requestPacket[OPCODE_INDEX+1] = requestType
		writeChecksum(toPacket: &requestPacket)
		
		let responseDescriptor = ORSSerialPacketDescriptor(
			maximumPacketLength: UInt(REQUEST_RESPONSE_LENGTH),
			userInfo: nil,
			responseEvaluator: { [requestType] data -> Bool in
				if data == nil || data!.count != REQUEST_RESPONSE_LENGTH {
					return false
				}
				
				return data![0] == PACKET_START_BYTE && data![REQUEST_RESPONSE_LENGTH-1] == PACKET_END_BYTE && LASerialDevice.validateResponse(forPacket: data!, requestType: requestType)
		})
		
		let request = ORSSerialRequest(dataToSend: requestPacket, userInfo: nil, timeoutInterval: timeout, responseDescriptor: responseDescriptor)
		
		_serialPort!.send(request)
	}
	
	// MARK: - ORSSerialPortDelegate
	
	func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
		os_log("Serial port %s was removed from system", log: Log.serial, type: .info, serialPort.path)
		serialDeviceIsReady = false
		_serialPort?.delegate = nil
		_serialPort = nil
	}
	
	func serialPortWasOpened(_ serialPort: ORSSerialPort) {
		os_log("Opened serial port %s. Sending ready request...", log: Log.serial, type: .info, serialPort.path)
		self.sendRequest(requestType: READY_REQUEST_TYPE, timeout: 1.0)
	}
	
	func serialPort(_ serialPort: ORSSerialPort, requestDidTimeout request: ORSSerialRequest) {
		if (_readyRequestRetries == MAX_CONNECTION_RETRIES) {
			os_log("Ready request failed for serial port %s", log: Log.serial, type: .info, serialPort.path)
			_readyRequestRetries = 0
		} else {
			os_log("Ready request did timeout for serial port %s. Retrying...", log: Log.serial, type: .debug, serialPort.path)
			self.sendRequest(requestType: READY_REQUEST_TYPE, timeout: pow(2.0, Double(_readyRequestRetries)))
			_readyRequestRetries += 1
		}
	}
	
	func serialPortWasClosed(_ serialPort: ORSSerialPort) {
		os_log("Closed serial port %s", type: .info, serialPort.path)
		serialDeviceIsReady = false
	}
	
	func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
		// TODO: handle errors
		os_log("Serial port %s encountered an error: %s", log: Log.serial, type: .error, serialPort.path, error.localizedDescription)
	}

	func serialPort(_ serialPort: ORSSerialPort, didReceiveResponse responseData: Data, to request: ORSSerialRequest) {
		let requestType = responseData[1]
		let responseCode = responseData[2]
		
		switch (requestType) {
		case READY_REQUEST_TYPE:
			os_log("Serial port %s recieved response to ready request with code %u", log: Log.serial, type: .info, serialPort.path, responseCode)
			
			_readyRequestRetries = 0
			if (responseCode == 1) {
				serialDeviceIsReady = true
				UserDefaults.standard.set(serialPort.path, forKey: PREFERENCES_SELECTED_DEVICE_KEY)
				UserDefaults.standard.synchronize()
			}
		default:
			return
		}
	}
}
