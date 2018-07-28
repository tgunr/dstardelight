//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
//  ReflectorsViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import AppKit

class QSOReflectorsViewController: NSViewController  {
    var reflectors: DSReflectors?
    var reflectorGateways: [DSReflector]?
    var reflectorsPending: Bool = false
    var updateWhenButtons: [NSButton]!
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate
    let defaultsManager: UserDefaultsManager = UserDefaultsManager.shared

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
    
    // MARK: View Methods
    override func awakeFromNib() {
        HLog().debug("")
        reflectorsPending = true
        reflectors = appDelegate.appReflectors
        reflectorGateways = reflectors?.reflectorGateways
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name(REFLECTORS_READY), object: nil)
    }

    override func viewDidLoad() {
        HLog().debug("")
        updateWhenButtons = [updateDailyButton, updateWeeklyButton, updateMonthlyButton]
        progressView.isHidden = true
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
            HLog().error("environment data not saved in UserDefaults")
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
        HLog().debug("New reflector found", newReflector.name )
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
        case "Montly":
            defaultsManager.updateFrequency = UpdateFrequency.monthly
        default:
            defaultsManager.updateFrequency = UpdateFrequency.weekly
        }
    }

    @IBAction func enableClicked(_ sender: NSButton) {
    }
    
    @IBAction func disableClicked(_ sender: NSButton) {
    }
    
    // MARK: Drag and Drop support

//    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
//        if tableView != reflectorsTableView {
//            return nil
//        }
//        let reflector = reflectorTableController.arrangedObjects[row] as? [AnyHashable : Any]
//        let item = NSPasteboardItem()
//        if let aReflector = reflector {
//            item.setPropertyList(aReflector, forType: NSPasteboard.PasteboardType("net.polymicro.Dummy.reflector"))
//        }
//        return item
//    }
//
//    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
//        if tableView != reflectorsTableView {
//            return false
//        }
//        tableView.setDropRow(row, dropOperation: .above)
//        return .move
//    }
//
//    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
//        let reflector = info.draggingPasteboard().propertyList(forType: NSPasteboard.PasteboardType("net.polymicro.Dummy.reflector")) as? [AnyHashable : Any]
//        if tableView != reflectorsTableView {
//            return false
//        }
//        var oldIndex: Int? = nil
//        if let aReflector = reflector {
//            oldIndex = (reflectorTableController.arrangedObjects as? NSArray)?.index(of: aReflector)
//        }
//        if let aReflector = reflector {
//            while let elementIndex = reflectorTableController.index(of: aReflector) { reflectorTableController.remove(at: elementIndex) }
//        }
//        if row < (oldIndex ?? 0) {
//            if let aReflector = reflector {
//                reflectorTableController.insert(aReflector, atArrangedObjectIndex: row)
//            }
//        } else {
//            if let aReflector = reflector {
//                reflectorTableController.insert(aReflector, atArrangedObjectIndex: row - 1)
//            }
//        }
//        return true
//    }
}

extension QSOReflectorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = reflectors?.reflectorGateways.count
        HLog().debug("numberOfRows: \(count ?? 0)")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if reflectorGateways?.count != 0 {
            let aReflector = reflectorGateways![ row ] as? DSReflector
            if let colID = tableColumn?.identifier.rawValue {
                switch colID {
                    case "reflectorName":
                        return aReflector?.name
                    case "reflectorIP":
                        return aReflector?.ip
                    default:
                        return "NONE"
                }
            }
        }
        HLog().error("No reflectors!")
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector = reflectorGateways?[row] as? DSReflector

    }

}

