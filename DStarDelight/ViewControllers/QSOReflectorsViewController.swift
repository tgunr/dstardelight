//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
//  ReflectorsViewController.m
//  DStarDelight
//
//  Created by Dave Carlton on 7/11/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import AppKit

// MARK: Data Source
extension QSOReflectorsViewController: NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        let count = reflectors?.reflectorGateways.count
        print("numberOfRows: \(count ?? 0)")
        return count ?? 0
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let aReflector = reflectorGateways?.object(at: row) as? DSReflector
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
        let aReflector = reflectorGateways?.object(at: row) as? DSReflector

    }

}

class QSOReflectorsViewController: NSViewController  {
    var reflectors: DSReflectors?
    var reflectorGateways: NSMutableArray?
        
    let appDelegate = NSApplication.shared.delegate as! HAppDelegate

    @IBOutlet var reflectorsTableView: NSTableView!
    @IBOutlet var reflectorsArrayController: NSArrayController!
    
// MARK: View Methods
    override func awakeFromNib() {
        reflectors = appDelegate.appReflectors
        reflectorGateways = reflectors?.reflectorGateways
        reflectorsArrayController = NSArrayController.init(content: reflectorGateways)
        
    }
    override func viewDidLoad() {
//        reflectorsTableView.registerForDraggedTypes([NSPasteboard.PasteboardType(rawValue: "net.polymicro.Dummy.reflector")])
//        reflectorsTableView.dataSource = self as? NSTableViewDataSource
//        reflectorsTableView.delegate = (self as! NSTableViewDelegate)
        
//        reflectorsTableView.enumerateAvailableRowViews({ rowView, row in
//            let reflectorsView: NSTextField? = (rowView.view(atColumn: 0) as? NSTableCellView)?.textField
//            //        if([reflectorsView.objectValue isEqualToString:destination])
//            //            reflectorsView.textColor = [NSColor redColor];
//        })
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
