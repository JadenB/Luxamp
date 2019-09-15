//
//  ArcLevelView.swift
//  LED Strip Controller
//
//  Created by Jaden Bernal on 1/15/19.
//  Copyright © 2019 Jaden Bernal. All rights reserved.
//

import Cocoa

@IBDesignable
class ArcLevelView: NSView {
    
    // MARK: - Variables
    
    weak var delegate: ArcLevelViewDelegate?
    
    private var colorArcLayer = AngleGradientArcLayer()
    private var brightnessArcLayer = AngleGradientArcLayer()
    
    private var colors: [CGColor] = [NSColor.red.cgColor, NSColor.yellow.cgColor] {
        didSet {
            (layer as? AngleGradientArcLayer)?.colors = colors
        }
    }
    
    // MARK: - Initializers
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
    }
    
    // MARK: - Visible Attributes
    
    @IBInspectable var arcWidth: CGFloat = 2.0 {
        didSet {
            brightnessArcLayer.arcWidth = arcWidth
            colorArcLayer.arcWidth = arcWidth
        }
    }
    
    @IBInspectable var arcStartAngle: CGFloat = 0 {
        didSet {
            brightnessArcLayer.arcEndAngle = 180 - arcStartAngle
            colorArcLayer.arcStartAngle = arcStartAngle
        }
    }
    
    @IBInspectable var arcEndAngle: CGFloat = 360 {
        didSet {
            brightnessArcLayer.arcStartAngle = 180 - arcEndAngle
            colorArcLayer.arcEndAngle = arcEndAngle
        }
    }
    
    @IBInspectable var levelLineWidth: CGFloat = 4.0 {
        didSet {
            colorArcLayer.levelWidth = levelLineWidth
            brightnessArcLayer.levelWidth = levelLineWidth
        }
    }
    
    var colorGradient: NSGradient {
        get { return colorArcLayer.gradient }
        set { colorArcLayer.gradient = newValue }
    }
    
    func setBrightnessLevel(to blevel: Float) {
        brightnessArcLayer.level = blevel
    }
    
    func setColorLevel(to clevel: Float) {
        colorArcLayer.level = clevel
    }
    
    // MARK: - Overrides
    
    override func makeBackingLayer() -> CALayer {
        let l = CALayer()
        l.needsDisplayOnBoundsChange = true
        l.backgroundColor = CGColor.clear
        l.frame = bounds
        
        brightnessArcLayer.frame = bounds
        brightnessArcLayer.gradient = NSGradient(starting: .black , ending: .white)
        brightnessArcLayer.invert = true
        brightnessArcLayer.level = 0.0
        l.addSublayer(brightnessArcLayer)
        
        colorArcLayer.frame = bounds
        colorArcLayer.gradient = NSGradient(starting: .red, ending: .yellow)
        colorArcLayer.level = 0.0
        l.addSublayer(colorArcLayer)
        return l
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
    override func mouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: window?.contentView)
        if brightnessArcLayer.contains(p) {
            print("hit brightess")
        } else if colorArcLayer.contains(p) {
            delegate?.arcLevelColorClicked(with: event)
        }
        
        super.mouseDown(with: event)
    }
    
    override func rightMouseDown(with event: NSEvent) {
        let p = convert(event.locationInWindow, from: window?.contentView)
        if brightnessArcLayer.contains(p) {
            print("right hit brightess")
        } else if colorArcLayer.contains(p) {
            let popupMenu = NSMenu(title: "Context Menu")
            popupMenu.addItem(withTitle: "Reset", action: #selector(resetColorPressed), keyEquivalent: "")
            NSMenu.popUpContextMenu(popupMenu, with: event, for: self)
        } else {
            print("right no hit")
        }
        
        super.rightMouseDown(with: event)
    }
    
    override func viewDidChangeBackingProperties() {
        layer?.contentsScale = window!.backingScaleFactor
    }
    
    override func layout() {
        super.layout()
        layer?.frame = frame
        layer?.layoutSublayers()
    }
    
    override func prepareForInterfaceBuilder() {
        colorArcLayer.level = 1
        brightnessArcLayer.level = 1
    }
    
    // MARK: - Selectors
    
    @objc private func resetColorPressed() {
        delegate?.arcLevelColorResetClicked()
    }
    
}


protocol ArcLevelViewDelegate: class {
    func arcLevelColorResetClicked()
    func arcLevelColorClicked(with event: NSEvent)
}
