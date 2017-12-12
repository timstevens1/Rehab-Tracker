//
//  SettingsViewController.swift
//  Rehab Tracker
//
//  Created by Tim Stevens on 12/10/17.
//  Copyright © 2017 CS 275 Project Group 6. All rights reserved.
//

import Foundation
import UIKit

class SettingsViewController: UIViewController {
    
    
    @IBAction func Logout(_ sender: Any) {
        print(Util.numberOfUsers())
        while Util.numberOfUsers() != 0 {
            print("is this running?")
            Util.deleteData()
        }
        print(Util.numberOfUsers())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
