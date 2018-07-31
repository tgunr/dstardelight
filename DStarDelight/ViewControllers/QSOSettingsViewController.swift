//  Converted to Swift 4 by Swiftify v4.1.6781 - https://objectivec2swift.com/
//
//  DSQSOSettingsViewController.swift
//  DStarDelight
//
//  Created by Dave Carlton on 7/12/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Cocoa

class QSOSettingsViewController: NSViewController {
    var logLevelButtons: [NSButton]!
    let defaultsManager: UserDefaultsManager = UserDefaultsManager.shared

    @IBOutlet var traceButton: NSButton!
    @IBOutlet var debugButton: NSButton!
    @IBOutlet var infoButton: NSButton!
    @IBOutlet var warningButton: NSButton!
    
    @IBAction func logLevelClick(_ sender: NSButton) {
        logLevelButtons.forEach { $0.state = NSControl.StateValue.off } // uncheck everything
        sender.state = NSControl.StateValue.on // check the button that is clicked

        let which = sender.title
        switch which {
            case "Trace":
                HLog().minLevel = .trace
            case "Debug":
                HLog().minLevel = .debug
            case "Info":
                HLog().minLevel = .info
            case "Warning":
                HLog().minLevel = .warning
            default:
                break
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logLevelButtons = [traceButton, debugButton, infoButton, warningButton]
    }
}
