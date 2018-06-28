//
//  LinkDriverProtocol.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
enum linkState1 : Int {
    case unlinked
    case connected
    case linking
    case linked
}
protocol BTRLinkDriverProtocol: class {
    var linkTarget: String { get }
    var vocoder: BTRVocoderDriver? { get set }
    var myCall: String { get set }
    var myCall2: String { get set }
    var delegate: (NSObject & BTRLinkDriverDelegate)? { get set }
    var linkQueue: DispatchQueue? { get set }
    var destinations: [String] { get }
    func canHandleLink(to reflector: String?) -> Bool
    func link(to linkTarget: String?)
    func unlink()
    func sendAMBE(_ data: UnsafeMutableRawPointer?, lastPacket last: Bool)
}
