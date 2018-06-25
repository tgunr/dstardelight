//
//  AppDelegate.swift
//  DStarDelight
//
//  Created by Dave Carlton on 6/10/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import AppKit
import CoreAudio

@NSApplicationMain
class BTRAppDelegate: NSObject, NSApplicationDelegate {

    override func awakeFromNib() {
        let mainBundle = Bundle.main
        let url = mainBundle.url(forResource: "DefaultPreferences", withExtension: "plist")
        let defaultPrefs = NSDictionary(contentsOf: url!)
        UserDefaults.standard.register(defaults: defaultPrefs as! [String : Any])
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationWillFinishLaunching(_ notification: Notification) {
        let engine = BTRDataEngine.sharedInstance()!
        let inputUID = UserDefaults.standard.string(forKey: "inputAudioDevice")
        if inputUID == nil {
            engine.audio.inputDevice = engine.audio.defaultInputDevice
        } else {
            let inputDevices = BTRAudioHandler.enumerateInputDevices()
            for device in inputDevices {
                let thisUID = device["uid"] as! String
                if thisUID == inputUID {
                    engine.audio.inputDevice = device["id"] as! AudioDeviceID
                }
            }
            let outputUID = UserDefaults.standard.string(forKey: "outputAudioDevice")
            if outputUID == nil {
                engine.audio.outputDevice = engine.audio.defaultOutputDevice
            } else {
                let outputDevices = BTRAudioHandler.enumerateOutputDevices()
                for device in outputDevices {
                    let thisUID = device["uid"] as! String
                    if thisUID == inputUID {
                        engine.audio.outputDevice = device["id"] as! AudioDeviceID
                    }
                }
            }
        }
    }
}
