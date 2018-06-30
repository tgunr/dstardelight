//
//  SlowDataDelegate.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation

protocol DSESlowDataDelegate: NSObjectProtocol {
    func slowDataReceived(_ slowData: String?, forStreamId streamId: NSNumber?)
    func locationReceived(_ location: DSEAprsLocation?, forStreamId streamId: NSNumber?)
}
