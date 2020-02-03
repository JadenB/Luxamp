//
//  LAFixture.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/1/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Cocoa


class LAFixture {
	enum ParameterType {
		case Dimmer
		case ColorRGB
		case Other
	}

	struct Parameter {
		let label: String
		let channelCount: Int
		let parameterType: ParameterType
		
		static func makeColorRGB() -> Parameter {
			return Parameter(label: "Color", channelCount: 3, parameterType: .ColorRGB)
		}
		
		static func makeDimmer() -> Parameter {
			return Parameter(label: "Dimmer", channelCount: 1, parameterType: .Dimmer)
		}
	}
	
	let id = UUID()
	
	private let parameters: [Parameter]
	private var parameterChannels: [[UInt8]] = []
	
	init(parameters: [Parameter]) {
		self.parameters = parameters
		for p in parameters {
			parameterChannels.append([UInt8](repeating: 0, count: p.channelCount))
		}
	}
	
	final var parameterCount: Int {
		return parameters.count
	}
	
	func sendChannels() {
		fatalError("Subclasses of LAFixture must implement sendChannels()")
	}
	
	final func writeToChannel(_ channel: Int, forParameter paramIndex: Int, value: UInt8) {
		parameterChannels[paramIndex][channel] = value
	}
	
	final func getParameter(_ index: Int) -> Parameter {
		return parameters[index]
	}
	
	// MARK: - Internal Functions
	
	final internal func getChannel(_ channel: Int, forParameter paramIndex: Int) -> UInt8 {
		return parameterChannels[paramIndex][channel]
	}
}
