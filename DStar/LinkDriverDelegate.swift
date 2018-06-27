//
//  LinkfileDelegate.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
protocol BTRLinkDriverDelegate: NSObjectProtocol {
    func addData(_ data: UnsafeMutableRawPointer?, streamId: Int)
    func getBytes(_ bytes: UnsafeMutableRawPointer?, forSequence sequence: Int)
    // MARK: - Delegate methods
    func destinationWillLink(_ destination: String?)
    func destinationDidLink(_ destination: String?)
    func destinationDidUnlink(_ destination: String?)
    func destinationDidConnect(_ destination: String?)
    func streamDidStart(_ header: [AnyHashable: Any]?)
    func streamDidEnd(_ streamId: NSNumber?, atTime date: Date?)
    func destinationDidError(_ destination: String?) throws
}
