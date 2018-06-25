//
//  ViewController.swift
//  DStarDelight
//
//  Created by Dave Carlton on 6/10/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource, NSControlTextEditingDelegate, BTRDataEngineDelegate {
    func streamDidStart(_ header: [AnyHashable : Any]!) {
        
    }
    
    func streamDidEnd(_ streamId: NSNumber!, atTime date: Date!) {
        
    }
    
    func slowDataReceived(_ slowData: String!, forStreamId streamId: NSNumber!) {
        
    }
    
    func locationReceived(_ location: CLLocation!, forStreamId streamId: NSNumber!) {
        
    }
    
    func destinationDidLink(_ destination: String!) {
        
    }
    
    func destinationDidUnlink(_ destination: String!) {
        
    }
    
    func destinationDidError(_ destination: String!, error: Error!) {
        
    }
    
    func destinationWillLink(_ destination: String!) {
        
    }
    
    func destinationDidConnect(_ destination: String!) {
        
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()

        BTRDataEngine.sharedInstance().delegate = self as! BTRDataEngineDelegate
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }


}

