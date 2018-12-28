//
//  GradientEditorViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 12/27/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class GradientEditorViewController: NSViewController {
    
    var gradient: NSGradient! = NSGradient(starting: .black, ending: .white) {
        didSet {
            gradientView.gradient = gradient
        }
    }
    @IBOutlet weak var gradientView: GradientView!
    
    var delegate: GradientEditorViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        self.view.window?.performClose(nil)
    }
    
    @IBAction func applyButtonPressed(_ sender: Any) {
        delegate?.didSetGradient(gradient: gradient)
        self.view.window?.performClose(nil)
    }
    
    @IBAction func redYellow(_ sender: Any) {
        gradient = NSGradient(starting: .red, ending: .yellow)
    }
    
    @IBAction func blueGreen(_ sender: Any) {
        gradient = NSGradient(starting: .blue, ending: .green)
    }
}

protocol GradientEditorViewControllerDelegate {
    func didSetGradient(gradient: NSGradient)
}
