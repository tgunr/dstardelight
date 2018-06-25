//
//  SettingsViewController.swift
//  DStarDelightIOS
//
//  Created by Dave Carlton on 6/25/18.
//  Copyright © 2018 Polymicro Systems. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var connectionStatus: UIImageView!
    
    @IBOutlet weak var ambeServer: UITextField!
    @IBOutlet weak var serverPort: UITextField!
    @IBOutlet weak var testButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

