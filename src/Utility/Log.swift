//
//  Log.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/3/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation
import os

struct Log {
	static let user = OSLog(subsystem: "com.jadenbernal.Luxamp", category: "user")
	static let serial = OSLog(subsystem: "com.jadenbernal.Luxamp", category: "serial")
	static let fixture = OSLog(subsystem: "com.jadenbernal.Luxamp", category: "fixture")
}
