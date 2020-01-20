//
//  RefreshTimer.swift
//  Luxamp
//
//  Created by Jaden Bernal on 1/19/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import Foundation


class RefreshTimer: NSObject {
	private let onTick: () -> Void
	private let interval: Double
	
	private lazy var timer: DispatchSourceTimer = {
		let q = DispatchQueue(label: "com.jadenbernal.Luxamp.refreshQueue")
		let t = DispatchSource.makeTimerSource(queue: q)
		t.schedule(deadline: .now() + interval, repeating: interval)
		t.setEventHandler { [weak self] in
			self?.onTick()
		}
		return t
	}()
	
	private enum State {
		case suspended
		case resumed
	}
	
	private var state: State = .suspended
	
	init(refreshRate: Double, block: @escaping () -> Void) {
		onTick = block
		interval = 1.0/refreshRate
	}
	
	deinit {
		timer.setEventHandler {}
        timer.cancel()
        start()
	}
	
	func start() {
		if state == .resumed {
			return
		}
		
		state = .resumed
		timer.resume()
	}
	
	func pause() {
		if state == .suspended {
			return
		}
		
		state = .suspended
		timer.suspend()
	}
}
