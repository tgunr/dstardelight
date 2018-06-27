//
//  DPlusLink.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation

struct dstar_frame {
    var magic = [Int8](repeating: 0, count: 4)
    //  "DSVT"
    var type = 0
    //  0x20 = AMBE, 0x10 = Header
    var unknown = [Int8](repeating: 0, count: 4)
    // { 0x00, 0x00, 0x00, 0x20 }
    var band = [Int8](repeating: 0, count: 3)
    //  { 0x00, 0x02, 0x01 }
    var id: UInt16 = 0
    var sequence = 0
}

struct dplus_packet {
    var length: UInt = 0
    var type = 0
    var padding = 0
//    var frame: dstar_frame?
    subscript(attr: String) -> Any? {
        get {
            if attr == "length" { return length }
            if attr == "size" { return length & 0x0fff }
            if attr == "type" { return type }
            if attr == "padding" { return padding }
            return nil
        }
        set {
            if attr == "length" { length = newValue as! UInt }
            if attr == "type" { type = newValue as! Int }
            if attr == "padding" { padding = newValue as! Int }
        }
    }
}

private let DPLUS_TYPE_POLL = 0x00
private let DPLUS_TYPE_LINK = 0x18
private let DPLUS_TYPE_LINKMODULE = 0x04
private let DPLUS_END_PATTERN = [0x55, 0x55, 0x55, 0x55, 0xc8, 0x7a, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
    
class DPlusLink {
    private(set) var unlinkPacket: Data?
    private(set) var pollPacket: Data?
    private(set) var linkPacket: Data?
    var authenticator: BTRDPlusAuthenticator?
    private(set) var ircDDBGateways: BTRIRCDDBGateways?

//    private var linkModuleTemplate = dplus_packet()
//    linkModuleTemplate["length"] = 0xc01c
//    linkModuleTemplate["type"] = DPLUS_TYPE_LINKMODULE
//    linkModuleTemplate.link.padding = 0x00
//    linkModuleTemplate.link.module.repeater = "    "
//    linkModuleTemplate.link.module.magic = "DV019999"

    class func load() {
        BTRDataEngine.registerLinkDriver(self)
    }
    
    init() {
        var unlinkPacket = dplus_packet()
        unlinkPacket["length"] = 0x05
        unlinkPacket["type"] = DPLUS_TYPE_LINK
        unlinkPacket["padding"] = 0x00
        unlinkPacket["state"] = 0x00
//        self.unlinkPacket = Data(bytes: &unlinkPacket, length: dplus_packet_size(unlinkPacket))
//        var pollPacket = dplus_packet()
//        pollPacket.length = 0x6003
//        pollPacket.link.type = DPLUS_TYPE_POLL
//        self.pollPacket = Data(bytes: &pollPacket, length: dplus_packet_size(pollPacket))
//        var linkPacket = dplus_packet()
//        linkPacket.length = 0x05
//        linkPacket.link.type = DPLUS_TYPE_LINK
//        linkPacket.link.padding = 0x00
//        linkPacket.link.state = 0x01
//        self.linkPacket = Data(bytes: &linkPacket, length: dplus_packet_size(linkPacket))
        authenticator = BTRDPlusAuthenticator()
        ircDDBGateways = BTRIRCDDBGateways()
    }
}
