//
//  DV3KVocoder.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/26/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
class BTRDV3KVocoder: NSObject, BTRVocoderDriver {
    var network: (NSObject & BTRLinkDriverProtocol)?
    
    static func driverName() -> String? {
        return ""
    }
    
    func decodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool) {
        
    }
    
    func encodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool) {
        
    }
    
    func start() -> Bool {
        return false
    }
    
    func stop() {
        
    }
    
    private(set) var productId = ""
    private(set) var version = ""
    override init() {
    }
}
