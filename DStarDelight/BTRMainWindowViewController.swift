//
//  MainWindowController.swift
//  DStarDelight
//
//  Created by Dave Carlton on 6/12/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import AppKit

class BTRMainWindowViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSControlTextEditingDelegate {
    @IBOutlet var heardTableController: NSArrayController!
    @IBOutlet weak var heardTableView: NSTableView!
    @IBOutlet weak var reflectorTableView: NSTableView!
    @IBOutlet var reflectorTableController: NSArrayController!
    @IBOutlet weak var statusLED: NSImageView!
    @IBOutlet weak var txButton: NSButton!
    @IBOutlet weak var repeaterInfo: NSTextField!
    private(set) var qsoList = [[AnyHashable: Any]]()
    var txKeyCode: MASShortcut?
    @IBOutlet weak var volumeSlider: NSSlider!
    @IBAction func doReflectorDoubleClick(_ sender: Any) {
    }
    @IBAction func doHeardDoubleClick(_ sender: Any) {
    }
    @IBAction func doLink(_ sender: Any) {
    }
    @IBAction func addReflector(_ sender: Any) {
    }
    @IBAction func doTx(_ sender: Any) {
    }
    @IBAction func doUnlink(_ sender: Any) {
    }
    @IBAction func doVolumeChange(_ sender: Any) {
    }
}
