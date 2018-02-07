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
    
    @IBAction func Feedback(_ sender: Any) {
        if let url = URL(string: "https://goo.gl/forms/jeWGFdvACDlcg2Br1"){
            UIApplication.shared.openURL(url)
        }
    }
    
    @IBOutlet weak var UserName: UILabel!
    @IBAction func Logout(_ sender: Any) {
        print(Util.numberOfUsers())
        while Util.numberOfUsers() > 0 {
            print("is this running?")
            Util.deleteData()
        }
        print(Util.numberOfUsers())
    }
    
    override func viewDidLoad() {
        UserName.text = "Welcome: "+Util.returnCurrentUsersID();
        super.viewDidLoad()

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
