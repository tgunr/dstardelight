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

let alpha: [ String ]
        = ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

class ReflectorsTableControl: NSObject, NSTableViewDataSource, NSTableViewDelegate {
    var appDelegate: HAppDelegate
    var connections: Connectors
    var tableView:   NSTableView?
    var controller:  QSOReflectorsViewController?

    override
    init() {
        appDelegate = NSApplication.shared.delegate as! HAppDelegate
        connections = appDelegate.connections
        super.init()
        HLog().debug("class: ", self.className)
    }

    init(controller: QSOReflectorsViewController, view: NSTableView) {
        appDelegate = NSApplication.shared.delegate as! HAppDelegate
        self.controller = controller
        self.tableView = view
        self.connections = appDelegate.connections
        super.init()
        HLog().debug("class: ", self.className)
    }

    required
    init?(coder aDecoder: NSCoder) {
        self.appDelegate = NSApplication.shared.delegate as! HAppDelegate
        connections = appDelegate.connections
        super.init(coder: aDecoder)
    }
}

class ReflectorsTable: ReflectorsTableControl {
    var reflectors: DSReflectors?

    override init() {
        super.init()
        HLog().debug("class: ", self.className)
    }

    override init(controller: QSOReflectorsViewController, view: NSTableView) {
        super.init(controller: controller, view: view)
    }

    required
    init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.appDelegate = NSApplication.shared.delegate as! HAppDelegate
        reflectors = controller?.reflectors
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        if let gateways: [ DSReflector ] = controller?.reflectors?.reflectorGateways() {
            count = gateways.count
        }
        HLog().debug("ReflectorsTable numberOfRows: \( count ?? 0 )")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        HLog().debug("row: ", row, " column: ", tableColumn?.identifier.rawValue)
        if controller?.reflectors?.reflectorGateways()?.count != 0 {
            let aReflector: DSReflector? = controller?.reflectors?.gateways[ row ]
            if let columnID: String = tableColumn?.identifier.rawValue {
                switch columnID {
                    case "ReflectorName":
                        return aReflector?.name
                    case "ReflectorIP":
                        return aReflector?.ip
                    default: break
                }
            }
            return "NONE"
        }
        return nil
    }
}

class ChannelsTable: ReflectorsTableControl {

    override init() {
        super.init()
        HLog().debug("class: ", self.className)
    }

    override init(controller: QSOReflectorsViewController, view: NSTableView) {
        super.init(controller: controller, view: view)
    }

    required
    init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.appDelegate = NSApplication.shared.delegate as! HAppDelegate
        HLog().debug("class: ", self.className)
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        return 26
        HLog().debug("ChannelsTable numberOfRows: 26 )")
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return alpha[ row ]
    }

}

class ConnectionsTable: ReflectorsTableControl {
    override init() {
        super.init()
        HLog().debug("class: ", self.className)
    }

    override init(controller: QSOReflectorsViewController, view: NSTableView) {
        super.init(controller: controller, view: view)
    }

    required
    init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.appDelegate = NSApplication.shared.delegate as! HAppDelegate
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        var count: Int = 0
        let list = connections.list
        count = list.count
        HLog().debug("ConnectionsTable numberOfRows: \( count ?? 0 )")
        return count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
//        HLog().debug("row: ", row, " column: ", tableColumn?.identifier.rawValue)
        let tag = tableView.tag
        if connections.list.count > 0 {
            if let columnID: String = tableColumn?.identifier.rawValue {
                let theConnector:   Connector    = connections.list[row]
                switch columnID {
                    case "ReflectorName":
                        let theReflector: DSReflector? = theConnector.connection as! DSReflector
                        return theReflector?.name
                    case "ReflectorChannel":
                        let theChannel: String? = (theConnector as! DSConnector).connectionChannel
                        return theChannel
                    default: break
                }
            }
        }
        return nil
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

    private
    var connectors: Connectors = Connectors()


    @IBOutlet var reflectorsView:            NSView!
    @IBOutlet var reflectorsTableView:       NSTableView!
    @IBOutlet var connectionsTableView:      NSTableView!
    @IBOutlet var channelTableView:          NSTableView!
    @IBOutlet var progressView:              NSProgressIndicator!
    @IBOutlet var reflectorsArrayController: NSArrayController!
    @IBOutlet var updateNowButton:           NSButton!
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
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name(kReflectorsAreReady), object: nil)

        progressView.isHidden = false
        reflectorsPending = true
        progressView.startAnimation(self)

        HLog().debug("loading reflectors")
        reflectors = DSReflectors().loadSavedReflectors()!
        connectors = appDelegate.connections

        reflectorsTable = ReflectorsTable(controller: self, view: reflectorsTableView)
        reflectorsTableView.delegate = reflectorsTable
        reflectorsTableView.dataSource = reflectorsTable

        channelsTable = ChannelsTable(controller: self, view: channelTableView)
        channelTableView.delegate = channelsTable
        channelTableView.dataSource = channelsTable

        connectionsTable = ConnectionsTable(controller: self, view: connectionsTableView)
        connectionsTableView.delegate = connectionsTable
        connectionsTableView.dataSource = connectionsTable

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
    @objc func reflectorsAreReady(_ notification: Notification?) {
        if reflectors == nil {
             reflectors = notification?.object as! DSReflectors
        }
        reflectorsPending = false
        if progressView != nil {
            progressView.isHidden = true
            progressView.stopAnimation(self)
        } else {
            HLog().warning("progressView: nil")
        }
        if reflectorsTableView != nil {
            reflectorsTableView.reloadData()
            connectionsTableView.reloadData()
        } else {
            HLog().warning("reflectorsTableView: nil")
        }
        HLog().info("count: ", reflectors?.gateways.count)
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
        let reflectorSelection = reflectorsTableView.selectedRow
        let channelSelection = channelTableView.selectedRow
        if reflectorSelection >= 0 && channelSelection >= 0 {
            let theReflector = reflectors?.gateways[reflectorSelection]
            let theChannel = alpha[channelSelection]
            let theConnection = DSConnector(reflector: theReflector!, channel: theChannel)
            theReflector?.active = true
            reflectors?.saveReflectorsToFile()
            connectors.dictionary[(theReflector?.name)!] = theConnection
            connectors.saveConnectionsToFile()
            connectionsTableView.reloadData()
        } else {
            Beep()
        }
    }
    
    @IBAction func disableClicked(_ sender: NSButton) {
        let selection = connectionsTableView.selectedRow
        if selection >= 0 {
            reflectors?.actives[ selection ].active = false
            reflectors?.saveReflectorsToFile()
            connectionsTableView.reloadData()
        } else {
            AudioServicesPlaySystemSound(kSystemSoundID_UserPreferredAlert)
        }
    }


}

