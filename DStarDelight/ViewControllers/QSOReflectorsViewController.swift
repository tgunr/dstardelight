//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
//  ReflectorsViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import AppKit
import AudioToolbox

class QSOReflectorsViewController: NSViewController  {
    var reflectors: DSReflectors?
    var reflectorsPending: Bool = false
    var updateWhenButtons: [NSButton]!
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate
    let defaultsManager: UserDefaultsManager = UserDefaultsManager.shared

    @IBOutlet var reflectorsView: NSView!
    @IBOutlet var reflectorsTableView: NSTableView!
    @IBOutlet var enabledTableView: NSTableView!
    @IBOutlet var reflectorsArrayController: NSArrayController!
    @IBOutlet var updateNowButton: NSButton!
    @IBOutlet var progressView: NSProgressIndicator!
    @IBOutlet var updateDailyButton: NSButton!
    @IBOutlet var updateWeeklyButton: NSButton!
    @IBOutlet var updateMonthlyButton: NSButton!
    @IBOutlet var enableButton: NSButton!
    @IBOutlet var disableButton: NSButton!

    // MARK: Access
    func reflectorGateways() -> [DSReflector]? {
        return reflectors?.reflectorGateways
    }

    func reflectorsActive() -> [DSReflector]? {
        return reflectorGateways()?.filter { $0.active }
    }

    // MARK: View Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        HLog().debug("")
        reflectorsArrayController = NSArrayController()
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        HLog().debug("")
        progressView.isHidden = true
        reflectorsPending = false
        reflectors = appDelegate.appReflectors
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name(REFLECTORS_READY), object: nil)

        updateWhenButtons = [updateDailyButton, updateWeeklyButton, updateMonthlyButton]
        updateWhenButtons.forEach { $0.state = NSControl.StateValue.off } // uncheck everything
        if let updateFrequency = UserDefaultsManager.shared.updateFrequency {
            switch updateFrequency {
                case UpdateFrequency.daily:
                    updateDailyButton.state = NSControl.StateValue.on // check the button that is clicked
                case UpdateFrequency.weekly:
                    updateWeeklyButton.state = NSControl.StateValue.on // check the button that is clicked
                case UpdateFrequency.monthly:
                    updateMonthlyButton.state = NSControl.StateValue.on // check the button that is clicked
            }
        } else {
            HLog().error("updateFrequency data not saved in UserDefaults")
        }

//        reflectorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "net.polymicro.Dummy.reflector")])
//        reflectorsTableView.dataSource = self as? NSTableViewDataSource
//        reflectorsTableView.delegate = (self as! NSTableViewDelegate)
        
//        reflectorsTableView.enumerateAvailableRowViews({ rowView, row in
//            let reflectorsView: NSTextField? = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField
//            //        if([reflectorsView.objectValue isEqualToString:destination])
//            //            reflectorsView.textColor = [NSColor redColor];
//        })
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if reflectorsPending {
            if progressView != nil {
                progressView.isHidden = false
                progressView.startAnimation(self)
            } else {
                HLog().warning("progressView: nil")
            }
        } else {
            if progressView != nil {
                progressView.isHidden = true
                progressView.stopAnimation(self)
            } else {
                HLog().warning("progressView: nil")
            }
        }
    }

    // MARK: Actions
    @objc
    func reflectorsAreReady(_ notification: Notification?) {
        let newReflectors: DSReflectors = notification?.object as! DSReflectors
        HLog().debug("new reflectors:", newReflectors.reflectorGateways.count)
        reflectors = newReflectors
        reflectorsPending = false
        if progressView != nil {
            progressView.isHidden = true
            progressView.stopAnimation(self)
        } else {
            HLog().warning("progressView: nil")
        }
        if reflectorsTableView != nil {
            reflectorsTableView.reloadData()
        } else {
            HLog().warning("reflectorsTableView: nil")
        }
    }

    @objc
    func newReflectorFound(_ notification: Notification?) {
        let newReflector: DSReflector = notification?.object as! DSReflector
        HLog().trace("New reflector found", newReflector.name )
    }

    @IBAction func updateNow(_ sender: Any) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.newReflectorFound(_:)), name: NSNotification.Name(NEW_REFLECTOR_FOUND), object: nil)
        progressView.isHidden = false
        progressView.startAnimation(self)
        reflectors?.reloadReflectors()
        reflectorsTableView.reloadData()
    }

    @IBAction func updateWhen(_ sender: NSButton) {
        updateWhenButtons.forEach { $0.state = NSControl.StateValue.off } // uncheck everything
        sender.state = NSControl.StateValue.on // check the button that is clicked
        
        let which = sender.title
        switch which {
        case "Daily":
            defaultsManager.updateFrequency = UpdateFrequency.daily
        case "Weekly":
            defaultsManager.updateFrequency = UpdateFrequency.weekly
        case "Monthly":
            defaultsManager.updateFrequency = UpdateFrequency.monthly
        default:
            defaultsManager.updateFrequency = UpdateFrequency.weekly
        }
    }

    @IBAction func enableClicked(_ sender: NSButton) {
        let selection = reflectorsTableView.selectedRow
        if selection >= 0 {
            reflectorGateways()![selection].active = true
            enabledTableView.reloadData()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
        }
    }
    
    @IBAction func disableClicked(_ sender: NSButton) {
        let selection = enabledTableView.selectedRow
        if selection >= 0 {
            reflectorsActive()![ selection ].active = false
            enabledTableView.reloadData()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
        }
    }
    
}

extension QSOReflectorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        let tag = tableView.tag
        switch tag {
            case 0:
                if let gateways = reflectorGateways() {
                    count = gateways.count
                }
            case 1:
                if let actives = reflectorsActive() {
                    count = actives.count
                }
            default: break
        }
        HLog().debug("numberOfRows: \(count ?? 0)")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let tag = tableView.tag
        switch tag {
            case 0:
                if reflectorGateways()?.count != 0 {
                    let aReflector: DSReflector = self.reflectorGateways()![ row ]
                    if let colID = tableColumn?.identifier.rawValue {
                        switch colID {
                            case "reflectorName":
                                return aReflector.name
                            case "reflectorIP":
                                return aReflector.ip
                            default:
                                break
                        }
                    }
                }
            case 1:
                if self.reflectorsActive()!.count != 0 {
                    let aReflector = self.reflectorsActive()![ row ]
                    return aReflector.name
                }
            default:
                HLog().error("No reflectors!")
        }
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector = reflectorGateways()![row] as? DSReflector

    }

}

