//
//  APRSLocation.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation
import CoreLocation
import MapKit
class BTRAprsLocation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    var location: CLLocation?
    var callsign = ""
    var messaging = [Bool]()
    var symbol = 0
    var symbolTable = 0
    private(set) var tnc2Packet = ""
    var comment = ""
    private(set) var dprsPacket = ""
    
    init(nmeaSentence: String?) {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    init(aprsPacket aprsString: String?) {
        coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
}
