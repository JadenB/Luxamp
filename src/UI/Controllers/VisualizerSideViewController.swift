//
//  VisualizerSideViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/31/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class VisualizerSideViewController: NSViewController {
    
    var mapper: VisualizerMapper!
    var name = "_"
    
    @IBOutlet weak var inputLevel: LegacyLevelView!
    @IBOutlet weak var inputLabel: NSTextField!
    @IBOutlet weak var outputLevel: LegacyLevelView!
    @IBOutlet weak var outputLabel: NSTextField!
    
    @IBOutlet weak var maxField: VisualizerTextField!
    @IBOutlet weak var minField: VisualizerTextField!
    
    @IBOutlet weak var invertCheckbox: NSButton!
    @IBOutlet weak var dynamicCheckbox: NSButton!
    
    @IBOutlet weak var driverMenu: NSPopUpButton!
    @IBOutlet weak var driverLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        populateMenus()
        refreshView()
        
        driverLabel.stringValue = name + " Driver"
    }
    
    func populateMenus() {
        driverMenu.addItems(withTitles: mapper.drivers())
        driverMenu.selectItem(at: 0)
    }
    
    func refreshView() {
        driverMenu.selectItem(withTitle: mapper.driverName())
        
        maxField.floatValue = mapper.inputMax
        minField.floatValue = mapper.inputMin
        
        invertCheckbox.state = mapper.invert ? .on : .off
        dynamicCheckbox.state = mapper.useDynamicRange ? .on : .off
        inputLevel.showSubrange = mapper.useDynamicRange
    }
    
    func updateWithData(_ data: VisualizerData) {
        inputLevel.level = remapValueToUnit(data.inputVal, min: mapper.inputMin, max: mapper.inputMax)
        inputLevel.subrangeMax = data.dynamicInputRange.max
        inputLevel.subrangeMin = data.dynamicInputRange.min
        inputLabel.stringValue = String(format: "%.1f", data.inputVal)
        
        outputLevel.level = data.outputVal
        outputLabel.stringValue = String(format: "%.1f", data.outputVal)
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if segue.identifier == "dynamicRangePopoverSegue" {
            let dynamicEditor = segue.destinationController as! DynamicRangeViewController
            dynamicEditor.dynamicRange = mapper.dynamicRange
        }
    }
    
    @IBAction func maxChanged(_ sender: VisualizerTextField) {
        mapper.inputMax = sender.floatValue
    }
    
    @IBAction func minChanged(_ sender: VisualizerTextField) {
        mapper.inputMin = sender.floatValue
    }
    
    @IBAction func invertChanged(_ sender: NSButton) {
        mapper.invert = (sender.state == .on)
    }
    
    @IBAction func dynamicChanged(_ sender: NSButton) {
        mapper.useDynamicRange = (sender.state == .on)
        inputLevel.showSubrange = mapper.useDynamicRange
        
        if sender.state == .on {
            performSegue(withIdentifier: "dynamicRangePopoverSegue", sender: sender)
        }
    }
    
    @IBAction func driverSelected(_ sender: NSPopUpButton) {
        guard let driverName = sender.selectedItem?.title else {
            print("error: no item selected")
            return
        }
        
        mapper.setDriver(withName: driverName)
    }
    
}
