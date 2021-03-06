//
//  ViewController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/19/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa


let REFRESH_RATE = 30.0


class ViewController: NSViewController, VisualizerDelegate,
                        ArcLevelViewDelegate, SaveDialogDelegate, GradientEditorDelegate {
    
    @IBOutlet weak var powerButton: NSButton!
    
    @IBOutlet weak var presetMenu: NSPopUpButton!
    @IBOutlet weak var presetMenuDeleteItem: NSMenuItem!
    @IBOutlet weak var arcLevelCenter: ArcLevelView!
    @IBOutlet weak var colorView: CircularColorWell!
    
    var brightnessSide: SideViewController!
    var colorSide: SideViewController!
	
	var viewport: ViewportViewController!
	
    var hidden = true
    var lastSelectedPresetName: String = ""
	
	var refreshTimer: RefreshTimer!
    
    var audioEngine: InputAudioTapper!
	var audioAnalyzer: AudioAnalyzer!
    var musicVisualizer: Visualizer!
	
	var currentBuffer: [Float] = [Float](repeating: 0.0, count: InputAudioTapper.BUFFER_SIZE)
	var currentBufferLock = UnsafeMutablePointer<pthread_mutex_t>.allocate(capacity: 1)
    
    var state: AppState = .Off {
        didSet {
            if state == .On {
                AppManager.disableSleep()
            } else {
                AppManager.enableSleep()
            }
        }
    }
	
	deinit {
		currentBufferLock.deallocate()
	}
    
    // MARK: - Overrides
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		if let selectedDevice = UserDefaults.standard.string(forKey: PREFERENCES_SELECTED_DEVICE_KEY) {
			if ORSSerialPortManager.shared().availablePorts.map({$0.path}).contains(selectedDevice) {
				FixtureManager.sharedFixture.connectToController(devicePath: selectedDevice)
			}
		}
		
		audioAnalyzer = AudioAnalyzer(bufferSize: InputAudioTapper.BUFFER_SIZE)
		audioEngine = InputAudioTapper()
		musicVisualizer = Visualizer()
		pthread_mutex_init(currentBufferLock, nil)
		
		audioEngine.setOnTap { [weak self] (buffer: [Float]) in
			guard let strongSelf = self else {
				return
			}
			
			pthread_mutex_lock(strongSelf.currentBufferLock)
			strongSelf.currentBuffer = buffer
			pthread_mutex_unlock(strongSelf.currentBufferLock)
		}
		
		refreshTimer = RefreshTimer(refreshRate: REFRESH_RATE) { [weak self] in
			guard let strongSelf = self else {
				return
			}
			
			DispatchQueue.main.async {
				pthread_mutex_lock(strongSelf.currentBufferLock)
				let audio = strongSelf.audioAnalyzer.analyze(buffer: strongSelf.currentBuffer)
				pthread_mutex_unlock(strongSelf.currentBufferLock)
				
				strongSelf.musicVisualizer.visualizeAudio(audio)
			}
		}
        
        musicVisualizer.delegate = self
        arcLevelCenter.delegate = self
        
        populateMenus()
    }
	
	override func viewWillAppear() {
		refreshViews()
	}
    
    override func viewDidAppear() {
        super.viewDidAppear()
        hidden = false
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        hidden = true
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
		if segue.identifier == nil {
			fatalError("Must set identifier for all segues in storyboard")
		}
		
        switch segue.identifier! {
        case .brightnessSideSegue:
            brightnessSide = segue.destinationController as? SideViewController
			brightnessSide.mapper = musicVisualizer.brightness
			brightnessSide.headTitle = "Brightness Control"
        case .colorSideSegue:
            colorSide = segue.destinationController as? SideViewController
			colorSide.mapper = musicVisualizer.color
			colorSide.headTitle = "Color Control"
        case .gradientEditorSegue:
            guard let gradientWindow = segue.destinationController as? NSWindowController else {
                NSLog("Failed to cast gradient window controller")
                return
            }
            
            let gradientEditor = gradientWindow.contentViewController as! GradientEditorViewController
            gradientEditor.gradient = musicVisualizer.gradient
            gradientEditor.delegate = self
        case .saveDialogSegue:
            let saveDialogController = segue.destinationController as! SaveDialogViewController
            saveDialogController.delegate = self
		case "viewportEmbedSegue":
			viewport = (segue.destinationController as! ViewportViewController)
        default:
            print("error: unidentified segue \(segue.identifier ?? "no identifier")")
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func powerButtonPressed(_ sender: NSButton) {
        state = (sender.state == .on) ? .On : .Off
        
        if state == .On {
			FixtureManager.sharedFixture.dimmer = 1.0
            startAudioVisualization()
            colorView.isEnabled = false
        } else {
			FixtureManager.sharedFixture.dimmer = 0.0
            stopAudioVisualization()
			colorView.color = .black
			viewport.lightColor = .black
			arcLevelCenter.setBrightnessLevel(to: 0.0)
			arcLevelCenter.setColorLevel(to: 0.0)
        }
		
		FixtureManager.sharedFixture.sendChannels()
    }
    
    @IBAction func presetSelected(_ sender: NSPopUpButton) {
        if sender.indexOfSelectedItem == sender.numberOfItems - 1 {
            let alert = NSAlert()
            alert.alertStyle = .warning
            alert.addButton(withTitle: "Delete")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "Are you sure you want to delete \"\(lastSelectedPresetName)\"?"
            alert.informativeText = "You are about to permanently delete this preset. Once deleted it cannot be recovered."
            alert.beginSheetModal(for: view.window!) { response in
                if response == .alertFirstButtonReturn {
                    self.deletePreset(withName: self.lastSelectedPresetName)
                }
            }
            
        } else if sender.indexOfSelectedItem == sender.numberOfItems - 2 {
            performSegue(withIdentifier: "saveDialogSegue", sender: self)
        } else {
            musicVisualizer.presets.apply(name: sender.selectedItem?.title ?? PRESETMANAGER_DEFAULT_PRESET_NAME)
            presetMenu.title = "Preset: " + (presetMenu.selectedItem?.title ?? "Error")
            if sender.selectedItem?.title == PRESETMANAGER_DEFAULT_PRESET_NAME {
                presetMenuDeleteItem.isEnabled = false
            } else {
                presetMenuDeleteItem.isEnabled = true
                lastSelectedPresetName = sender.selectedItem!.title
            }
            
            refreshViews()
        }
    }
    
    func savePreset(withName name: String) {
        musicVisualizer.presets.saveCurrentSettings(name: name)
        presetMenu.insertItem(withTitle: name, at: presetMenu.numberOfItems - 3)
        presetMenu.selectItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func deletePreset(withName name: String) {
        presetMenu.selectItem(at: 1)
        musicVisualizer.presets.delete(name: name)
        presetMenu.removeItem(withTitle: name)
        presetSelected(presetMenu)
    }
    
    func startAudioVisualization() {
		refreshTimer.start()
        audioEngine.startTappingInput()
    }
    
    func stopAudioVisualization() {
		refreshTimer.pause()
        audioEngine.stopTappingInput()
		brightnessSide.clearViews()
		colorSide.clearViews()
    }
    
    func refreshViews() {
        arcLevelCenter.colorGradient = musicVisualizer.gradient
		brightnessSide.refreshViews()
		colorSide.refreshViews()
    }
    
    func populateMenus() {
        let presetNames = musicVisualizer.presets.getNames()
        for i in (0..<presetNames.count).reversed() {
            presetMenu.insertItem(withTitle: presetNames[i], at: 1) // insert at 1 to put after title and before save/delete
        }
        presetMenu.selectItem(at: 1)
    }
    
    // MARK: - VisualizerDelegate
    
    func didVisualizeIntoColor(_ color: NSColor, brightnessVal: Float, colorVal: Float) {
		if self.state == .On {
			FixtureManager.sharedFixture.color = color
			FixtureManager.sharedFixture.sendChannels()
			self.colorView.color = color
			self.viewport.lightColor = color
			
			self.arcLevelCenter.setBrightnessLevel(to: brightnessVal)
			self.arcLevelCenter.setColorLevel(to: colorVal)
		}
    }
    
    func didVisualizeWithData(brightnessData: VisualizerData, colorData: VisualizerData) {
		if self.state == .On {
			self.brightnessSide.updateWithData(brightnessData)
			self.colorSide.updateWithData(colorData)
		}
    }
    
    // MARK: - ArcLevelViewDelegate
    
    func arcLevelColorResetClicked() {
        musicVisualizer.gradient = musicVisualizer.presets.defaultP.gradient
        arcLevelCenter.colorGradient = musicVisualizer.gradient
    }
    
    func arcLevelColorClicked(with event: NSEvent) {
        performSegue(withIdentifier: .gradientEditorSegue, sender: nil)
    }
    
    // MARK: - SaveDialogDelegate
    
    func saveDialogSaved(withName name: String, _ sender: SaveDialogViewController) {
        if name == PRESETMANAGER_DEFAULT_PRESET_NAME || name == "Delete Preset" || name == "Save Preset..." {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.messageText = "Invalid Preset Name"
            alert.informativeText = "Please choose a different name"
            alert.beginSheetModal(for: view.window!, completionHandler: nil)
        } else if musicVisualizer.presets.getNames().contains(name) {
            let alert = NSAlert()
            alert.alertStyle = .critical
            alert.addButton(withTitle: "Replace")
            alert.addButton(withTitle: "Cancel")
            alert.messageText = "\"\(name)\" already exists. Do you want to replace it?"
            alert.informativeText = "A preset with the same name already exists. Replacing it will overwrite its current settings."
            alert.beginSheetModal(for: view.window!) { response in
                if response == .alertFirstButtonReturn {
                    self.savePreset(withName: name)
                    sender.dismiss(nil)
                }
            }
        } else {
            savePreset(withName: name)
            sender.dismiss(nil)
        }
    } // end saveDialogSaved()
    
    func saveDialogCanceled(_ sender: SaveDialogViewController) {
        sender.dismiss(nil)
    }
    
    // MARK: - GradientEditorDelegate
    
    func gradientEditorSetGradient(_ gradient: NSGradient) {
        musicVisualizer.gradient = gradient
        arcLevelCenter.colorGradient = gradient
    }
    
}

enum AppState {
    case On
    case Off
}

extension NSStoryboardSegue.Identifier {
    static let saveDialogSegue = NSStoryboardSegue.Identifier("saveDialogSegue")
    static let gradientEditorSegue = NSStoryboardSegue.Identifier("gradientEditorSegue")
    static let brightnessSideSegue = NSStoryboardSegue.Identifier("brightnessSideSegue")
    static let colorSideSegue = NSStoryboardSegue.Identifier("colorSideSegue")
}

