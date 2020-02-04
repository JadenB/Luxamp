//
//  LAFixtureStripRGB.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/29/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Cocoa


class LAFixtureStripRGB: LAFixture {
	let DIMMER_PARAMETER = 0
	let COLOR_PARAMETER = 1
	
	private let sender = LASerialDevice(channelCount: 4)
	
	var dimmer: Double = 0.0 {
		didSet {
			let remapped = remapValueFromUnit(dimmer, min: 0.0, max: 255.0)
			writeToChannel(0, forParameter: DIMMER_PARAMETER, value: UInt8(remapped))
		}
	}
	
	var color: NSColor = .black {
		didSet {
			let rCom = UInt8(color.redComponent * 255.0)
			writeToChannel(0, forParameter: COLOR_PARAMETER, value: rCom)
			
			let gCom = UInt8(color.greenComponent * 255.0)
			writeToChannel(1, forParameter: COLOR_PARAMETER, value: gCom)
			
			let bCom = UInt8(color.blueComponent * 255.0)
			writeToChannel(2, forParameter: COLOR_PARAMETER, value: bCom)
		}
	}
	
	init() {
		super.init(
			defaultName: "RGB Strip",
			parameters: [.makeDimmer(), .makeColorRGB()]
		)
	}
	
	override func sendChannels() {
		sender.startChannelSend()
		sender.sendChannel(channel: 0, value: getChannel(0, forParameter: DIMMER_PARAMETER))
		sender.sendChannel(channel: 1, value: getChannel(0, forParameter: COLOR_PARAMETER))
		sender.sendChannel(channel: 2, value: getChannel(1, forParameter: COLOR_PARAMETER))
		sender.sendChannel(channel: 3, value: getChannel(2, forParameter: COLOR_PARAMETER))
		sender.endChannelSend()
	}
	
	func connectToController(devicePath: String) {
		sender.connectToDevice(withPath: devicePath)
	}
	
	func disconnectFromController() {
		sender.disconnectFromDevice()
	}
}
