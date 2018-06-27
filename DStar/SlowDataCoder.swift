//
//  SlowDataCoder.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import CoreLocation
class BTRSlowDataCoder: NSObject, CLLocationManagerDelegate {
    var message = ""
    weak var delegate: (NSObject & BTRSlowDataDelegate)?
    func addData(_ data: UnsafeMutableRawPointer?, streamId: Int) {
    }
    func getBytes(_ bytes: UnsafeMutableRawPointer?, forSequence sequence: Int) {
    }
}
