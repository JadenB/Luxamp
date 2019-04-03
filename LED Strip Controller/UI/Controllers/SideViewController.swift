//
//  SideViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/30/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class SideViewController: NSViewController, RangeControlDelegate {
	
	var mapper: VisualizerMapper!

	@IBOutlet weak var scrollingLevel: ScrollingLevelView!
	@IBOutlet weak var outputLevel: AdjustableLevelView!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		scrollingLevel.delegate = self
		scrollingLevel.identifier = .scrollingLevel
		outputLevel.delegate = self
		outputLevel.identifier = .outputLevel
    }
	
	override func viewDidAppear() {
		scrollingLevel.isHidden = false
	}
	
	override func viewDidDisappear() {
		scrollingLevel.isHidden = true
	}
    
    func updateWithData(_ data: VisualizerData) {
		outputLevel.level = data.outputVal
		scrollingLevel.pushLevel(data.inputVal)
		
		if mapper.useDynamicRange {
			scrollingLevel.lowerValue = data.dynamicInputRange.min
			scrollingLevel.upperValue = data.dynamicInputRange.max
		}
    }
	
	func refreshViews() {
		scrollingLevel.lowerValue = mapper.inputMin
		scrollingLevel.upperValue = mapper.inputMax
		outputLevel.lowerValue = mapper.outputMin
		outputLevel.upperValue = mapper.outputMax
	}
	
	// MARK: - RangeControlDelegate
	
	func rangeControlSlidersChanged(_ sender: RangeControl) {
		guard let id = sender.identifier else {
			print("no identifier!")
			return
		}
		
		if id == .scrollingLevel {
			mapper.inputMin = sender.lowerValue
			mapper.inputMax = sender.upperValue
		} else if id == .outputLevel {
			mapper.outputMin = sender.lowerValue
			mapper.outputMax = sender.upperValue
		}
	}
}

extension NSUserInterfaceItemIdentifier {
	static let scrollingLevel = NSUserInterfaceItemIdentifier("scrl")
	static let outputLevel = NSUserInterfaceItemIdentifier("outl")
}
