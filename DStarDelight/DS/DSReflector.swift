//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
// Created by Dave Carlton on 7/13/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation

// References a reflector
class DSReflector: NSObject {
    var name = ""
    var ip = ""
    var active = false

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {

        self.name = ""
        self.ip = ""
        self.active = false
        super.init()

        if let archivedName = aDecoder.decodeObject(forKey: "reflectorName") as? String {
            self.name = archivedName
        }

        if let archiveIP: String = aDecoder.decodeObject(forKey: "reflectorIP") as? String {
            self.ip = archiveIP
        }

        if aDecoder.containsValue(forKey: "reflectorActive") {
            self.active = aDecoder.decodeBool(forKey: "reflectorActive")
        }

    }

//
//    override func encode(with aCoder: NSCoder) {
//        aCoder.encode(name, forKey: "reflectorName")
//        aCoder.encode(ip, forKey: "reflectorIP")
//        aCoder.encode(active, forKey: "reflectorActive")
//
//    }

}
