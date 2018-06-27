//
//  DataEngineDelegate.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import CoreLocation
protocol BTRDataEngineDelegate: NSObjectProtocol {
    func streamDidStart(_ header: [AnyHashable: Any]?)
    func streamDidEnd(_ streamId: NSNumber?, atTime date: Date?)
    func slowDataReceived(_ slowData: String?, forStreamId streamId: NSNumber?)
    func locationReceived(_ location: CLLocation?, forStreamId streamId: NSNumber?)
    func destinationDidLink(_ destination: String?)
    func destinationDidUnlink(_ destination: String?)
    func destinationDidError(_ destination: String?) throws
    func destinationWillLink(_ destination: String?)
    func destinationDidConnect(_ destination: String?)
}
