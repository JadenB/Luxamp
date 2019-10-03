//
//  SaveDialogController.swift
//  Luxamp
//
//  Created by Jaden Bernal on 12/29/18.
//  Copyright © 2018 Jaden Bernal. All rights reserved.
//

import Cocoa

class SaveDialogViewController: NSViewController, NSTextFieldDelegate {
    
    weak var delegate: SaveDialogDelegate?
    @IBOutlet weak var field: NSTextField!
    @IBOutlet weak var saveButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        field.delegate = self
        saveButton.isEnabled = false
    }
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        delegate?.saveDialogSaved(withName: field.stringValue, self)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        delegate?.saveDialogCanceled(self)
    }
    
    // MARK: - NSTextFieldDelegate
    
    func controlTextDidChange(_ obj: Notification) {
        if field.stringValue == "" {
            saveButton.isEnabled = false
        } else {
            saveButton.isEnabled = true
        }
    }
}

protocol SaveDialogDelegate: class {
    func saveDialogSaved(withName name: String, _ sender: SaveDialogViewController)
    func saveDialogCanceled(_ sender: SaveDialogViewController)
}
