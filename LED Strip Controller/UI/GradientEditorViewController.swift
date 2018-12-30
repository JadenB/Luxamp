//
//  GradientEditorViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/27/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

let MAX_GRADIENT_COLORS = 5

class GradientEditorViewController: NSViewController {
    
    @IBOutlet weak var stackView: NSStackView!
    var gradient: NSGradient! = NSGradient(starting: .black, ending: .white) {
        didSet {
            gradientView.gradient = gradient
            setColorCount(count: gradient.numberOfColorStops)
        }
    }
    
    @IBOutlet weak var gradientView: GradientView!
    @IBOutlet weak var countStepper: NSStepper!
    @IBOutlet weak var countField: NSTextField!
    
    @IBOutlet weak var colorWell1: NSColorWell!
    @IBOutlet weak var colorWell2: NSColorWell!
    @IBOutlet weak var colorWell3: NSColorWell!
    @IBOutlet weak var colorWell4: NSColorWell!
    @IBOutlet weak var colorWell5: NSColorWell!
    
    var colorWells: [NSColorWell] = []
    var colorsUsed: Int = 0
    
    var delegate: GradientEditorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupColorWells()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
    }
    
    @IBAction func stepperChanged(_ sender: NSStepper) {
        setColorCount(count: sender.integerValue)
    }
    
    @IBAction func numberFieldChanged(_ sender: NSTextField) {
        setColorCount(count: sender.integerValue)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.view.window?.performClose(nil)
    }
    
    @IBAction func applyButtonPressed(_ sender: Any) {
        delegate?.didSetGradient(gradient: gradient)
        self.view.window?.performClose(nil)
    }
    
    func setupColorWells() {
        colorWells.reserveCapacity(5)
        colorWells.append(colorWell1)
        colorWells.append(colorWell2)
        colorWells.append(colorWell3)
        colorWells.append(colorWell4)
        colorWells.append(colorWell5)
        
        for cw in colorWells {
            cw.action = #selector(colorWellColorChanged)
        }
    }
    
    @objc func colorWellColorChanged() {
        updateGradientFromColorWells()
    }
    
    func updateGradientFromColorWells() {
        var colors = [NSColor]()
        colors.reserveCapacity(colorsUsed)
        
        for i in 0..<colorsUsed {
            colors.append(colorWells[i].color)
        }
        
        gradient = NSGradient(colors: colors)
    }
    
    func setColorCount(count: Int) {
        if count == colorsUsed {
            return
        }
        
        countStepper.integerValue = count
        countField.integerValue = count
        colorsUsed = count
        
        for i in 0..<MAX_GRADIENT_COLORS {
            colorWells[i].isHidden = (i >= colorsUsed)
        }
        
        for i in 0..<colorsUsed {
            colorWells[i].color = gradient.interpolatedColor(atLocation: CGFloat(i) * 1 / (CGFloat(colorsUsed) - 1))
        }
        
        updateGradientFromColorWells()
    }
}

protocol GradientEditorViewControllerDelegate {
    func didSetGradient(gradient: NSGradient)
}
