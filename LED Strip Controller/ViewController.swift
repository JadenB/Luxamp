//
//  ViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, AudioReaderDelegate {
    
    var prevAmp: Double = 0.0
    
    func updateWithAudioData(frequency: Double, amplitude: Double) {
        let newColor = NSColor(hue: 1, saturation: 1, brightness: CGFloat(amplitude), alpha: 1)
        color = newColor
    }
    
    @IBOutlet weak var colorView: ColorView!
    var colorPanel: NSColorPanel!
    var audioRead: AudioReader!
    
    var color: NSColor = NSColor(hue: 0, saturation: 1, brightness: 1, alpha: 1) {
        didSet {
            colorView.fillColor = color
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioRead = AudioReader(updateFrequency: 60, delegate: self)
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        audioRead.start()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func redButtonPressed(_ sender: Any) {
        color = NSColor.red
    }
    
    @IBAction func greenButtonPressed(_ sender: Any) {
        color = NSColor.green
    }
    
    @IBAction func customButtonPressed(_ sender: Any) {
        if colorPanel == nil {
            colorPanel = NSColorPanel.shared
            colorPanel.center()
            colorPanel.setTarget(self)
            colorPanel.setAction(#selector(colorPanelChanged))
        }
        
        colorPanel.color = color
        colorPanel.display()
        colorPanel.makeKeyAndOrderFront(nil)
    }
    
    @objc func colorPanelChanged() {
        color = colorPanel.color
    }
    

}

