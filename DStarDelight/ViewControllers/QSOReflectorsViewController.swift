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

class ReflectorsTableControl: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var appDelegate: HAppDelegate
    var reflectors:  DSReflectors?
    var tableView:   NSTableView?

    override
    init() {
        appDelegate = NSApplication.shared.delegate as! HAppDelegate
        reflectors = appDelegate.appReflectors
        super.init()
    }

    init(view: NSTableView) {
        appDelegate = NSApplication.shared.delegate as! HAppDelegate
        reflectors = appDelegate.appReflectors
        tableView = view
        super.init()
    }

    required
    init?(coder aDecoder: NSCoder) {
        self.appDelegate = NSApplication.shared.delegate as! HAppDelegate
        reflectors = appDelegate.appReflectors
        super.init(coder: aDecoder)
    }
}

class ReflectorsTable: ReflectorsTableControl {

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        let tag        = tableView.tag
        switch tag {
            case 0:
                if let gateways: [ DSReflector ] = reflectors?.reflectorGateways() {
                    count = gateways.count
                }
            case 1:
                if let actives: [ DSReflector ] = reflectors?.actives {
                    count = actives.count
                }
            default: break
        }
        HLog().debug("numberOfRows: \( count ?? 0 )")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        HLog().debug("row: ", row, " column: ", tableColumn?.identifier.rawValue)
        let tag = tableView.tag
        switch tag {
            case 0:
                if reflectors?.reflectorGateways()?.count != 0 {
                    let aReflector: DSReflector? = reflectors?.gateways[ row ]
                    if let colID: String = tableColumn?.identifier.rawValue {
                        switch colID {
                            case "reflectorName":
                                return aReflector?.name
                            case "reflectorIP":
                                return aReflector?.ip
                            default:
                                break
                        }
                    }
                }
            case 1:
                if reflectors?.reflectorsActive()!.count != 0 {
                    let aReflector: DSReflector = ( reflectors?.actives[ row ] )!
                    return aReflector.name
                }
            default:
                HLog().error("No reflectors!")
        }
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectcValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector: DSReflector? = reflectors?.reflectorGateways()?[ row ] as? DSReflector
    }
}

class ChannelsTable: ReflectorsTableControl {

    let alpha: [ String ]
            = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 26
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return alpha[ row ]
    }

    func tableView(_ tableView: NSTableView, setObjectcValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector: DSReflector? = reflectors?.reflectorGateways()?[ row ] as? DSReflector
    }
}

class ConnectionsTable: ReflectorsTableControl {
    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        let tag        = tableView.tag
        switch tag {
            case 0:
                if let gateways: [ DSReflector ] = reflectors?.reflectorGateways() {
                    count = gateways.count
                }
            case 1:
                if let actives: [ DSReflector ] = reflectors?.actives {
                    count = actives.count
                }
            default: break
        }
        HLog().debug("numberOfRows: \( count ?? 0 )")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        HLog().debug("row: ", row, " column: ", tableColumn?.identifier.rawValue)
        let tag = tableView.tag
        switch tag {
            case 0:
                if reflectors?.reflectorGateways()?.count != 0 {
                    let aReflector: DSReflector? = reflectors?.gateways[ row ]
                    if let colID: String = tableColumn?.identifier.rawValue {
                        switch colID {
                            case "reflectorName":
                                return aReflector?.name
                            case "reflectorIP":
                                return aReflector?.ip
                            default:
                                break
                        }
                    }
                }
            case 1:
                if reflectors?.reflectorsActive()!.count != 0 {
                    let aReflector: DSReflector = ( reflectors?.actives[ row ] )!
                    return aReflector.name
                }
            default:
                HLog().error("No reflectors!")
        }
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectcValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector: DSReflector? = reflectors?.reflectorGateways()?[ row ] as? DSReflector
    }
}

class QSOReflectorsViewController: NSViewController  {
    var reflectors:        DSReflectors?
    var reflectorsPending: Bool = false
    var updateWhenButtons: [NSButton]!
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate
    let defaultsManager:   UserDefaultsManager = UserDefaultsManager.shared
    var reflectorsTable:   ReflectorsTable?
    var channelsTable:     ChannelsTable?
    var connectionsTable:  ConnectionsTable?

    @IBOutlet var reflectorsView:            NSView!
    @IBOutlet var reflectorsTableView:       NSTableView!
    @IBOutlet var enabledTableView:          NSTableView!
    @IBOutlet var channelTableView:          NSTableView!
    @IBOutlet var reflectorsArrayController: NSArrayController!
    @IBOutlet var updateNowButton:           NSButton!
    @IBOutlet var progressView:              NSProgressIndicator!
    @IBOutlet var updateDailyButton:         NSButton!
    @IBOutlet var updateWeeklyButton:        NSButton!
    @IBOutlet var updateMonthlyButton:       NSButton!
    @IBOutlet var enableButton:              NSButton!
    @IBOutlet var disableButton:             NSButton!

    // MARK: Access

    // MARK: View Methods
    override func awakeFromNib() {
        super.awakeFromNib()
        HLog().debug("")
        reflectorsArrayController = NSArrayController()
    }

    override
    func viewDidLoad() {
        super.viewDidLoad()
        HLog().debug("")
        progressView.isHidden = true
        reflectorsPending = false
        reflectors = appDelegate.appReflectors
        reflectorsTable = ReflectorsTable(view: reflectorsTableView)
        reflectorsTableView.delegate = reflectorsTable
        reflectorsTableView.dataSource = reflectorsTable
        channelsTable = ChannelsTable(view: channelTableView)
        channelTableView.delegate = channelsTable
        channelTableView.dataSource = channelsTable
        connectionsTable = ConnectionsTable(view: enabledTableView)
        enabledTableView.delegate = connectionsTable
        enabledTableView.dataSource = connectionsTable
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name(kReflectorsAreReady), object: nil)
        updateWhenButtons = [updateDailyButton, updateWeeklyButton, updateMonthlyButton]
        updateWhenButtons.forEach {
            $0.state = NSControl.StateValue.off
        } // uncheck everything
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
        HLog().debug("new reflectors:", newReflectors.reflectorGateways()?.count)
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.newReflectorFound(_:)), name: NSNotification.Name(kNewReflectorFound), object: nil)
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

    // TODO: enable/disable according to focus
    @IBAction func enableClicked(_ sender: NSButton) {
        let selection = reflectorsTableView.selectedRow
        if selection >= 0 {
            reflectors?.reflectorGateways()![ selection ].active = true
            reflectors?.saveReflectorsToFile()
            enabledTableView.reloadData()
        } else {
            Beep()
        }
    }
    
    @IBAction func disableClicked(_ sender: NSButton) {
        let selection = enabledTableView.selectedRow
        if selection >= 0 {
            reflectors?.actives[ selection ].active = false
            reflectors?.saveReflectorsToFile()
            enabledTableView.reloadData()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
        }
    }
    
}

