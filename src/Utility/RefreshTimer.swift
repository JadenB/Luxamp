//
//  RefreshTimer.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/19/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class RefreshTimer: NSObject {
	private var timer: Timer
	private let onTick: () -> Void
	private let interval: Double
	
	init(refreshRate: Double, block: @escaping () -> Void) {
		timer = Timer()
		onTick = block
		interval = 1.0/refreshRate
	}
	
	deinit {
		timer.invalidate()
	}
	
	func start() {
		timer.invalidate()
		timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) {[weak self] _ in
			self?.onTick()
		}
	}
	
	func pause() {
		timer.invalidate()
	}
}
