//
//  ViewportViewController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 2/13/20.
//  Copyright © 2020 Jaden Bernal. All rights reserved.
//

import SceneKit
import QuartzCore

class ViewportViewController: NSViewController {
	private var stripLightNode1: SCNNode?
	private var stripLightNode2: SCNNode?
	private var stripLightNode3: SCNNode?
	private var stripMaterial: SCNMaterial?
	
	private var movingHeadLightNode: SCNNode?
	private var movingHeadMaterial: SCNMaterial?
	
	var lightColor: NSColor = .black {
		didSet {
			let calibrated = lightColor.usingColorSpace(.deviceRGB)!
			let neonColor = NSColor(calibratedHue: calibrated.hueComponent, saturation: calibrated.saturationComponent, brightness: (2.0+log(calibrated.brightnessComponent))/2, alpha: 1.0)
			
			stripLightNode1?.light!.color = lightColor
			stripLightNode2?.light!.color = lightColor
			stripLightNode3?.light!.color = lightColor
			stripMaterial?.emission.contents = neonColor
			
			movingHeadLightNode?.light!.color = lightColor
			movingHeadMaterial?.emission.contents = neonColor
		}
	}
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // create a new scene
        let scene = SCNScene(named: "art.scnassets/room.scn")!
        
        // retrieve the ship node
		stripLightNode1 = scene.rootNode.childNode(withName: "strip_light1", recursively: true)!
		stripLightNode2 = scene.rootNode.childNode(withName: "strip_light2", recursively: true)!
		stripLightNode3 = scene.rootNode.childNode(withName: "strip_light3", recursively: true)!
		
		let ledStrip = scene.rootNode.childNode(withName: "strip_mesh", recursively: true)!
		stripMaterial = ledStrip.geometry?.material(named: "light_material")
		
		let movingHead = scene.rootNode.childNode(withName: "MOVINGHEAD_FIXTURE", recursively: true)!
		
		let tiltUpAction = SCNAction.rotateBy(x: .pi / 4, y: 0, z: 0, duration: 2)
		tiltUpAction.timingMode = .easeInEaseOut
		let tiltDownAction = SCNAction.rotateBy(x: -.pi / 4, y: 0, z: 0, duration: 2)
		tiltDownAction.timingMode = .easeInEaseOut
		
		movingHead.childNode(withName: "pan_rotate", recursively: true)!.runAction(SCNAction.repeatForever(SCNAction.rotateBy(x: 0, y: 1, z: 0, duration: 1)))
		movingHead.childNode(withName: "tilt_rotate", recursively: true)!.runAction(SCNAction.repeatForever(SCNAction.sequence([tiltUpAction, tiltDownAction])))
		
		movingHeadLightNode = movingHead.childNode(withName: "light_mesh", recursively: true)!.childNode(withName: "spot_light", recursively: false)
		movingHeadMaterial = movingHead.childNode(withName: "light_mesh", recursively: true)!.geometry?.material(named: "light_material")
        
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // set the scene to the view
        scnView.scene = scene
        
        // allows the user to manipulate the camera
        scnView.allowsCameraControl = false
		scnView.preferredFramesPerSecond = 30
        
        // show statistics such as fps and timing information
        scnView.showsStatistics = false
        
        // configure the view
        scnView.backgroundColor = NSColor.black
        
        // Add a click gesture recognizer
        let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(handleClick(_:)))
        var gestureRecognizers = scnView.gestureRecognizers
        gestureRecognizers.insert(clickGesture, at: 0)
        scnView.gestureRecognizers = gestureRecognizers
    }
    
    @objc
    func handleClick(_ gestureRecognizer: NSGestureRecognizer) {
        // retrieve the SCNView
        let scnView = self.view as! SCNView
        
        // check what nodes are clicked
        let p = gestureRecognizer.location(in: scnView)
        let hitResults = scnView.hitTest(p, options: [:])
        // check that we clicked on at least one object
        if hitResults.count > 0 {
            // retrieved the first clicked object
            let result = hitResults[0]
            
            // get its material
            let material = result.node.geometry!.firstMaterial!
            
            // highlight it
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            // on completion - unhighlight
            SCNTransaction.completionBlock = {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.5
                
                material.emission.contents = NSColor.black
                
                SCNTransaction.commit()
            }
            
            material.emission.contents = NSColor.red
            
            SCNTransaction.commit()
        }
    }
}

