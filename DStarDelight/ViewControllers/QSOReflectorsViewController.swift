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
    var updateWhenButtons: [NSButton]!
    
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate

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
        reflectors = appDelegate.appReflectors
        reflectorGateways = reflectors?.reflectorGateways
        reflectorsArrayController = NSArrayController.init(content: reflectorGateways)
    }

    override func viewDidLoad() {
        HLog().debug("")
        progressView.isHidden = false
        progressView.startAnimation(self)
        updateWhenButtons = [updateDailyButton, updateWeeklyButton, updateMonthlyButton]
//        reflectorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "net.polymicro.Dummy.reflector")])
//        reflectorsTableView.dataSource = self as? NSTableViewDataSource
//        reflectorsTableView.delegate = (self as! NSTableViewDelegate)
        
//        reflectorsTableView.enumerateAvailableRowViews({ rowView, row in
//            let reflectorsView: NSTextField? = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField
//            //        if([reflectorsView.objectValue isEqualToString:destination])
//            //            reflectorsView.textColor = [NSColor redColor];
//        })
    }

    // MARK: Actions
    @objc
    func reflectorsAreReady(_ notification: Notification?) {
        let newReflectors: DSReflectors = notification?.object as! DSReflectors
        reflectors = newReflectors
        progressView.stopAnimation(self)
        reflectorsTableView.reloadData()
    }

    @objc
    func newReflectorFound(_ notification: Notification?) {
        let newReflector: DSReflector = notification?.object as! DSReflector
        HLog().debug("New reflector found", newReflector.name )
    }

    @IBAction func updateNow(_ sender: Any) {
        NotificationCenter.default.addObserver(self, selector: #selector(self.reflectorsAreReady(_:)), name: NSNotification.Name(REFLECTORS_READY), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.newReflectorFound(_:)), name: NSNotification.Name(NEW_REFLECTOR_FOUND), object: nil)
        progressView.startAnimation(self)
        reflectors?.reloadReflectors()
        reflectorsTableView.reloadData()
    }

    @IBAction func updateWhen(_ sender: NSButton) {
        updateWhenButtons.forEach { $0.state = NSControl.StateValue.off } // uncheck everything
        sender.state = NSControl.StateValue.on // check the button that is clicked o
    }

    @IBAction func enableClicked(_ sender: NSButton) {
    }
    
    @IBAction func disableClicked(_ sender: NSButton) {
    }
    
    // MARK: Reflector Drag and Drop support

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

    override func viewDidAppear() {
        self.reflectorsTableView.reloadData()
    }
}

// MARK: Data Source
extension QSOReflectorsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = reflectors?.reflectorGateways.count
        HLog().debug("numberOfRows: \(count ?? 0)")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let aReflector = reflectorGateways![row] as? DSReflector
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
        return "NONE"
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        let aReflector = reflectorGateways?[row] as? DSReflector

    }

}

