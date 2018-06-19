//
//  ReflectorsView.swift
//  DStarDelight
//
//  Created by Dave Carlton on 6/18/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
class ReflectorsViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSControlTextEditingDelegate  {
    
    @IBOutlet var reflectorsView: NSView!
    @IBOutlet weak var reflectorsTable: NSTableView!
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var reflector = "REF001 A"
        return reflector
    }
    func numberOfRows(in tableView: NSTableView) -> Int {
        let nRows = 2
        return nRows
    }
}
