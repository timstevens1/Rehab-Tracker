//
//  ViewController.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 11/1/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import UIKit
import CoreData
import Foundation
import CoreBluetooth
import UserNotifications

/// This class represents the main page that allows users to login and get into the app
class ViewController: UIViewController, UITextFieldDelegate {
    /// Text box to type user name
    @IBOutlet weak var loginBar: UITextField!
    /// Text box that actually updates user name
    @IBAction func enterUserID(_ sender: Any) {
        self.updateUserID(ID: loginBar.text!)
    }
    /// Update user ID based on what's typed in
    /// - Parameter ID: User ID
    private func updateUserID(ID: String){
        while Util.numberOfUsers() != 0 {
            // Delete all core data
            Util.deleteData()
        }
        self.saveUserID(ID);
        self.viewDidLoad();
    }
    /// Create a User and add in their userID
    /// - Parameter thisUserID: User ID
    private func saveUserID(_ thisUserID: String) {
        // Save entered userID to persistent core data
        let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
        let user = User(context: context)
        user.userID = thisUserID
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
        //COMPLETE ME!
        print()
        // register new user for push notifications
       
    }

    /// Respond to add user button,check to see if there's already a user logged in, save user to core data, and allow for overwrites
    @IBAction func AddUser(_ sender: AnyObject) {
        
        if Util.numberOfUsers() > 0 {
            // Creates pop-up alert UIAlertController
            let overWriteAlert = UIAlertController(title: "Overwrite",
                                                   message: "There is already a User logged in, would you like to overwrite them? Warning: This will erase their data.",
                                                   preferredStyle: .alert)
            
            // Creates the save button in the alert
            let saveAction = UIAlertAction(title: "Yes", style: .default, handler:
            {
                                            (action:UIAlertAction) -> Void in
                                            // Delete other user
                                            while Util.numberOfUsers() != 0 {
                                                // Delete all core data
                                                Util.deleteData()
                                            }
                
                                            // Alert to take input and save it
                                            // Creates pop-up alert UIAlertController
                                            let alert = UIAlertController(title: "Username",
                                                                          message: "Add a new username",
                                                                          preferredStyle: .alert)
                                            
                                            // Creates the save button in the alert
                                            let saveAction = UIAlertAction(title: "Save",
                                                                           style: .default,
                                                                           handler: { (action:UIAlertAction) -> Void in
                                                                            
                                                                            // Calls saveUserID function with input as arguement
                                                                            let textField = alert.textFields!.first
                                                                            self.saveUserID(textField!.text!)
                                                                            self.viewDidLoad()
                                            })
                                            
                                            // Creates the cancel button which exits without saving input
                                            let cancelAction = UIAlertAction(title: "Cancel",
                                                                             style: .default) { (action: UIAlertAction) -> Void in
                                            }
                                            
                                            // Textfield for input
                                            alert.addTextField {
                                                (textField: UITextField) -> Void in
                                            }
                                            
                                            alert.addAction(saveAction)
                                            alert.addAction(cancelAction)
                                            self.present(alert,
                                                    animated: true,
                                                    completion: nil)
            })
        
        
            // Creates the cancel button which exits without saving input
            let cancelAction = UIAlertAction(title: "No",
                                             style: .default) { (action: UIAlertAction) -> Void in }
            
            overWriteAlert.addAction(saveAction)
            overWriteAlert.addAction(cancelAction)
            self.present(overWriteAlert, animated: true, completion: nil)
        }
        if Util.numberOfUsers() == 0 {
            // Alert to take input and save it
            let alert = UIAlertController(title: "Username",
                                          message: "Add a new username",
                                          preferredStyle: .alert)
            
            // Creates the save button in the alert
            let saveAction = UIAlertAction(title: "Save",
                                           style: .default,
                                           handler: { (action:UIAlertAction) -> Void in
                                        
                                            //calls saveUserID function with input as arguement
                                            let textField = alert.textFields!.first
                                            self.saveUserID(textField!.text!)
                                            self.viewDidLoad()
            })
            
            // Creates the cancel button which exits without saving input
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .default) { (action: UIAlertAction) -> Void in }
            
            // Textfield for input
            alert.addTextField {(textField: UITextField) -> Void in }
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }

    /// Let user with a valid ID log in and continue on to the sync page
    @IBAction func Continue(_ sender: UIButton) {
        // If username is valid, allows the user to continue into the app
        if !(loginBar.text == ""){ self.updateUserID(ID: loginBar.text!)}
        if (Util.returnCurrentUsersID() == Util.getDatabaseUsername()){
            // Continues on to the syncviewcontroller
            Util.pushRegistration()
            let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle:nil)
            let nextViewController = storyBoard.instantiateViewController(withIdentifier: "Sync")
            self.present(nextViewController, animated:true, completion:nil)
        }
        else {
            // Alert to tell user they arent properly logged in
            var Message = "Could not find userID: "
            Message += Util.returnCurrentUsersID()
            let alert = UIAlertController(title: "Invalid Login",
                                          message: Message,
                                          preferredStyle: .alert)
            
            // Creates the okay button in the alert
            let okayAction = UIAlertAction(title: "Okay",
                                           style: .default,
                                           handler: { (action:UIAlertAction) -> Void in
            })
            alert.addAction(okayAction)
            self.present(alert,
                         animated: true,
                         completion: nil)
        }
    }
    
    /// Global variable to store returned userID check from database
    private var returnedUserID = ""
    
    /// Check if a username is in the database; if yes, return the name as string
    override func viewDidLoad() {
        super.viewDidLoad()
        self.returnedUserID = Util.getDatabaseUsername()
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        
        //Uncomment the line below if you want the tap not not interfere and cancel other interactions.
        //tap.cancelsTouchesInView = false
        
        view.addGestureRecognizer(tap)
        self.loginBar.delegate = self;
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    /// Cause the view (or one of its embedded text fields) to resign the first responder status.
    func dismissKeyboard() {
        view.endEditing(true)
    }
    /// Cause the view (or one of its embedded text fields) to resign the first responder status.
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return false
    }
    /// Sent to the view controller when the app receives a memory warning.
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

