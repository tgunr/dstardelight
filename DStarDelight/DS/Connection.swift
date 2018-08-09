//
// Created by Dave Carlton on 8/1/18.
// Copyright (c) 2018 Polymicro Systems. All rights reserved.
//

import Foundation

class Connector {
    var connection: Any?

    init() {
        connection = nil
    }

    init(connector: Any?) {
        connection = connector
    }
}

class DSConnector: Connector {
    var connectionChannel: String?

    init(reflector: DSReflector, channel: String) {
        super.init(connector: reflector)
        self.connectionChannel = channel
    }
}

class Connectors {
    var dictionary: [ String : Connector ] = [ : ]

    func save() {
        if ( self.dictionary.count != 0 )  {
            let defaultsURL: URL? = UserDefaultsManager.shared.defaultsURL(filename: kHamsterConnections)
            UserDefaultsManager.shared.saveToFile(url: defaultsURL!)
        }
    }

}