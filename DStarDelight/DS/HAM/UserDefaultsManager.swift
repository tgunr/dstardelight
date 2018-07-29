//
// Created by Dave Carlton on 7/27/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import Log

enum UpdateFrequency: Int {
    case daily = 1, weekly = 7, monthly = 30
}


let kUpdateFrequencyDefaultsKey  = "updateFrequency"
let kLogLevel = "logLevel"

class UserDefaultsManager {

    static let shared = UserDefaultsManager()

    var updateFrequency: UpdateFrequency? {
        get {
            guard let updateFrequency = UserDefaults.standard.value(forKey: kUpdateFrequencyDefaultsKey) as? Int else {
                return nil
            }
            return UpdateFrequency(rawValue: updateFrequency)
        }
        set(updateFrequency) {
            UserDefaults.standard.set(updateFrequency?.rawValue, forKey: kUpdateFrequencyDefaultsKey)
        }
    }
}
