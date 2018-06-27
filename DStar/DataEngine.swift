//
//  DataEngine.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Foundation

var linkDriverClasses = [AnyClass]()

class BTRDataEngine: NSObject, BTRLinkDriverDelegate, BTRSlowDataDelegate {
    
    static let sharedInstance = BTRDataEngine()
    private(set) weak var network: (NSObject & BTRLinkDriverProtocol)?
    weak var vocoder: BTRVocoderDriver?
    private(set) var audio: AudioHandler?
    private(set) var slowData: BTRSlowDataCoder?
    weak var delegate: (NSObject & BTRDataEngineDelegate)?
    private(set) var linkDriverDestinations = [String]()
    private var vocoderDrivers: [AnyHashable]? = nil

    override init() {
    }

    class func registerVocoderDriver(_ driver: AnyClass) {
    }
    
    class func registerLinkDriver(_ driver: AnyClass) {
        linkDriverClasses.append(driver)
    }
    
    class func vocoderDrivers() -> [Any]? {
        return nil
    }

    func addData(_ data: UnsafeMutableRawPointer?, streamId: Int) {
        
    }
    
    func getBytes(_ bytes: UnsafeMutableRawPointer?, forSequence sequence: Int) {
        
    }
    
    func destinationWillLink(_ destination: String?) {
        
    }
    
    func destinationDidLink(_ destination: String?) {
        
    }
    
    func destinationDidUnlink(_ destination: String?) {
        
    }
    
    func destinationDidConnect(_ destination: String?) {
        
    }
    
    func streamDidStart(_ header: [AnyHashable : Any]?) {
        
    }
    
    func streamDidEnd(_ streamId: NSNumber?, atTime date: Date?) {
        
    }
    
    func destinationDidError(_ destination: String?) throws {
        
    }
    
    func slowDataReceived(_ slowData: String?, forStreamId streamId: NSNumber?) {
        
    }
    
    func locationReceived(_ location: BTRAprsLocation?, forStreamId streamId: NSNumber?) {
        
    }
    
    func isDestinationValid(_ destination: String?) -> Bool {
        return false
    }
    func link(to reflector: String?) {
    }
    func unlink() {
    }
}
