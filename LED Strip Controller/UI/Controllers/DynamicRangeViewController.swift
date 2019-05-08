//
//  DynamicRangeViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/7/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class DynamicRangeViewController: NSViewController {
    
    var dynamicRange: DynamicRange!
    
    @IBOutlet weak var aggressionLabel: NSTextField!
    @IBOutlet weak var aggressionSlider: NSSlider!

    @IBOutlet weak var rangeTopCheckbox: NSButton!
    @IBOutlet weak var rangeBottomCheckbox: NSButton!
    
	override func viewWillAppear() {
		super.viewWillAppear()
		aggressionSlider.floatValue = dynamicRange.aggression
		aggressionLabel.stringValue = String(format: "%.2f", dynamicRange.aggression)
		rangeTopCheckbox.state = dynamicRange.useMax ? .on : .off
		rangeBottomCheckbox.state = dynamicRange.useMin ? .on : .off
	}
    
    @IBAction func aggressionSliderChanged(_ sender: NSSlider) {
        dynamicRange.aggression = sender.floatValue
        aggressionLabel.stringValue = String(format: "%.2f", sender.floatValue)
    }
    
    @IBAction func rangeTopChanged(_ sender: NSButton) {
        let state = (sender.state == .on)
        dynamicRange.useMax = state
    }
    
    @IBAction func rangeBottomChanged(_ sender: NSButton) {
        let state = (sender.state == .on)
        dynamicRange.useMin = state
    }
    
}
