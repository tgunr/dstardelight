//
//  DPlusAuthenticator.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
class BTRDPlusAuthenticator: NSObject {
    var authCall = ""
    private(set) var reflectorList = [AnyHashable: Any]()
    private(set) var authenticated = false
}
