//  Converted to Swift 4 by Swiftify v4.1.6766 - https://objectivec2swift.com/
//
// Created by Dave Carlton on 7/13/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation

// References a reflector
class DSReflector: NSObject {

    var name:   String = ""
    var ip:     String = ""
    var active: Bool   = false

    override init() {
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        self.name = ""
        self.ip = ""
        self.active = false

        if let archivedName = aDecoder.decodeObject(forKey: "reflectorName") as? String {
            self.name = archivedName
        }

        if let archiveIP = aDecoder.decodeObject(forKey: "reflectorIP") as? String {
            self.ip = archiveIP
        }

        if let isActive: Bool = aDecoder.decodeBool(forKey: "reflectorActive") {
            self.active = isActive
        }
    }


    override func encode(with aCoder: NSCoder) {
        aCoder.encode(name, forKey: "reflectorName")
        aCoder.encode(ip, forKey: "reflectorIP")
        aCoder.encode(active, forKey: "reflectorActive")
        super.encode(with: aCoder)
    }

}
