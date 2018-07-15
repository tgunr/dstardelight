//
//  HAppDelegate.swift
//  DStarDelight
//
//  Created by Dave Carlton on 7/15/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import AppKit

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    var reflectors: DSReflectors?
    
    let shared = NSApplication.shared.delegate
    
    //MARK: Data reading and writing functions
    
    func readStringFromFile(fileName:String) -> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: "txt")
            
            else {return nil}
        do { //Error showing following line
            let contents = try String(contentsOfFile: filepath, encoding: String.Encoding.utf8)
            
            return contents
        }catch{
            print ("File Read Error")
            return nil
        }
    }
    
    override func awakeFromNib() {
        let audioHandler = DSAudioHandler()
        DSVars.shared().audioHandler = audioHandler

        let path = Bundle.main.path(forResource: "DefaultPreferences", ofType: "plist")
        let defaultPrefs: NSDictionary? = NSDictionary(contentsOfFile: path!)
        if let aPrefs = defaultPrefs {
            UserDefaults.standard.register(defaults: aPrefs as! [String : Any])
        }
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name("reflectorsAreReady"), object: nil)
        reflectors = DSReflectors()
    }
    
    @objc func reflectorsAreReady(_ notification: Notification?) {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name("reflectorsAreReady"), object: nil)
    }
    
    func applicationWillFinishLaunching(_ aNotification: Notification) {
        let engine: DSEDataEngine = DSEDataEngine.sharedInstance()
        engine.slowData.bind(NSBindingName("message"), to: NSUserDefaultsController.shared, withKeyPath: "values.slowDataMessage", options: nil)
        let inputUid: String? = UserDefaults.standard.string(forKey: "inputAudioDevice")
        if inputUid == nil {
            engine.audio.inputDevice = engine.audio.defaultInputDevice()
        } else {
            for entry in DSAudioHandler.enumerateInputDevices() {
                let dictItem: [ String : Any ] = entry as! [String : Any]
                let dictItemUID = dictItem["uid"] as! String
                    if dictItemUID == inputUid {
                    engine.audio.inputDevice = 0
                }
            }
        }
        let outputUid = UserDefaults.standard.string(forKey: "outputAudioDevice")
        if outputUid == nil {
            engine.audio.outputDevice = engine.audio.defaultOutputDevice()
        } else {
            for entry in DSAudioHandler.enumerateOutputDevices() {
                let dictItem: [ String : Any ] = entry as! [String : Any]
                let dictItemUID = dictItem["uid"] as! String
                if dictItemUID == inputUid {
                    engine.audio.outputDevice = 0
                }
            }
        }
        let nName: NSNotification.Name = NSNotification.Name(rawValue: DSAudioDeviceChanged)
        NotificationCenter.default.addObserver(forName: nName, object: nil, queue: OperationQueue.main, using:
        { notification in
            for entry in DSAudioHandler.enumerateInputDevices() {
                let dictItem: [ String : Any ] = entry as! [String : Any]
                let itemUID:AudioDeviceID = dictItem["id"] as! AudioDeviceID
                if itemUID == engine.audio.inputDevice {
                    UserDefaults.standard.set(itemUID, forKey: "inputAudioDevice")
                }
            }
            for entry in DSAudioHandler.enumerateOutputDevices() {
                let dictItem: [ String : Any ] = entry as! [String : Any]
                let itemUID:AudioDeviceID = dictItem["id"] as! AudioDeviceID
                if itemUID == engine.audio.inputDevice {
                    UserDefaults.standard.set(itemUID, forKey: "outputAudioDevice")
                }
            }
        })
        DispatchQueue.global(qos: .default).async(execute: {
            engine.audio.start()
            engine.audio.setOutputVolume(UserDefaults.standard.float(forKey: "outputVolume"))
            engine.vocoder.start()
        })
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UserDefaults.standard.set(reflectors, forKey: "reflectors")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

}
