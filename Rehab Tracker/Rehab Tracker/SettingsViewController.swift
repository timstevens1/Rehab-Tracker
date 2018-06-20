//
//  SettingsViewController.swift
//  Rehab Tracker
//
//  Created by Tim Stevens on 12/10/17.
//  Copyright © 2017 CS 275 Project Group 6. All rights reserved.
//

import Foundation
import UIKit

/// View controller for the settings page
class SettingsViewController: UIViewController {
    /// Feedback button that will open the feedback page after user clicks on it
    /// - Postcondition: A browser is opened and linked to the feedback page (Google forms).
    @IBAction func Feedback(_ sender: Any) {
        if let url = URL(string: "https://goo.gl/forms/jeWGFdvACDlcg2Br1"){
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    /// A label that shows the user's name
    @IBOutlet weak var UserName: UILabel!
    
    /// Log out button
    @IBAction func Logout(_ sender: Any) {
        print(Util.numberOfUsers())
        while Util.numberOfUsers() > 0 {
            print("is this running?")
            Util.deleteData()
        }
        print(Util.numberOfUsers())
    }
    
    /// Called after the controller's view is loaded into memory
    override func viewDidLoad() {
        UserName.text = "Welcome: "+Util.returnCurrentUsersID();
        super.viewDidLoad()

    }
    
    /// Sent to the view controller when the app receives a memory warning.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
