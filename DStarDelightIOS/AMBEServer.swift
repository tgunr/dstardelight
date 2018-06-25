//
//  AMBEServer.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation

enum serverStatus: UInt8 {
    case disconnected = 0
    case connected = 1
    case busy = 2
}

class AMBEServer {
    var address: String?
    var port = 2460
    var status = serverStatus.disconnected
    
    func connect() -> serverStatus {
        return serverStatus.disconnected
    }
}
