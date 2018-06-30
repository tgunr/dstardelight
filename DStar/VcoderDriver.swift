//
//  VcoderDriver.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/26/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
protocol DSEVocoderDriver: NSObjectProtocol {
//    var audio: DSEAudioHandler? { get set }
    var network: (NSObject & DSELinkDriverProtocol)? { get set }
//    private(set) var configurationViewController: NSViewController? { get }
    static func driverName() -> String?
    func decodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool)
    func encodeData(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool)
    func start() -> Bool
    func stop()
}
