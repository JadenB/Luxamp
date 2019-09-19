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
	var headTitle: String = ""

	@IBOutlet weak var titleLabel: NSTextField!
	@IBOutlet weak var detectRangeButton: NSButton!
	@IBOutlet weak var driverMenu: NSPopUpButton!
	@IBOutlet weak var scrollingLevel: ScrollingLevelView!
	@IBOutlet weak var outputLevel: AdjustableLevelView!
	@IBOutlet weak var smoothingView: SmoothingView!
	@IBOutlet weak var invertButton: NSButton!
	@IBOutlet weak var smoothingSlider: NSSlider!
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		titleLabel.stringValue = headTitle
		
		scrollingLevel.delegate = self
		scrollingLevel.identifier = .scrollingLevel
		outputLevel.delegate = self
		outputLevel.identifier = .outputLevel
		
		populateMenus()
		refreshViews()
    }
	
	override func viewDidAppear() {
		scrollingLevel.isHidden = false
	}
	
	override func viewDidDisappear() {
		scrollingLevel.isHidden = true
	}
	
	override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		if segue.identifier == .dynamicRangePopoverSegue {
			let drController = segue.destinationController as! DynamicRangeViewController
			drController.dynamicRange = mapper.dynamicRange
		}
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
		
		detectRangeButton.state = mapper.useDynamicRange ? .on : .off
		scrollingLevel.isEnabled = !mapper.useDynamicRange
		driverMenu.selectItem(withTitle: mapper.driverName())
		
		invertButton.state = mapper.invert ? .on : .off
		
		smoothingView.smoothing = CGFloat(mapper.upwardsSmoothing)
		smoothingSlider.floatValue = mapper.upwardsSmoothing
	}
	
	func clearViews() {
		scrollingLevel.clear()
		outputLevel.clear()
	}
	
	private func populateMenus() {
		let driverNames = mapper.drivers()
		for driverName in driverNames {
			driverMenu.addItem(withTitle: driverName)
		}
	}
	
	@IBAction func detectRangePressed(_ sender: NSButton) {
		mapper.useDynamicRange = (sender.state == .on)
		scrollingLevel.isEnabled = !mapper.useDynamicRange
		if !mapper.useDynamicRange {
			mapper.inputMin = scrollingLevel.lowerValue
			mapper.inputMax = scrollingLevel.upperValue
		}
	}
	
	@IBAction func driverChanged(_ sender: NSPopUpButton) {
		mapper.setDriver(withName: sender.selectedItem!.title)
		
		scrollingLevel.min = 0.0
		scrollingLevel.max = 1.0
		scrollingLevel.lowerValue = 0.0
		scrollingLevel.upperValue = 1.0
	}
	
	@IBAction func invertPressed(_ sender: NSButton) {
		mapper.invert = (sender.state == .on)
	}
	
	@IBAction func smoothingChanged(_ sender: NSSlider) {
		mapper.upwardsSmoothing = sender.floatValue
		mapper.downwardsSmoothing = sender.floatValue
		smoothingView.smoothing = CGFloat(sender.floatValue)
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

extension NSStoryboardSegue.Identifier {
	static let dynamicRangePopoverSegue = NSStoryboardSegue.Identifier("dynamicRangePopoverSegue")
}

extension NSUserInterfaceItemIdentifier {
	static let scrollingLevel = NSUserInterfaceItemIdentifier("scrl")
	static let outputLevel = NSUserInterfaceItemIdentifier("outl")
}
