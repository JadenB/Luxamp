//
//  SideViewController.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/30/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

class SideViewController: NSViewController {
    
    var mapper: VisualizerMapper!

    @IBOutlet weak var scrollingGraph: ScrollingGraphView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    func updateWithData(_ data: VisualizerData) {
        scrollingGraph.append(value: data.outputVal)
    }
}
