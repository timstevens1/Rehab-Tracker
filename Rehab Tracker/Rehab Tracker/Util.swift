//
//  Util.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 2/14/17.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import UIKit
import CoreData
import Foundation

/// This class includes a bunch of utility functions used throughout the code
class Util {
    /// User's device ID
    static var UDID : String = ""
    /// Patient's ID for database
    static var DBuser : String = "No User"
    /// Last synced date
    static var lastSynced : String = "Never"
    /// Number of sessions completed in that week
    static var numSessions : String = "0 "
    
    /// Return the host URL
    /// - Returns: Host URL (https://rehabtracker.med.uvm.edu)
    class func getHOST() -> String{
        return "https://rehabtracker.med.uvm.edu/"
    }
    /// Return current User's userID as a string from core data
    /// - Returns: User's ID
    class func returnCurrentUsersID() -> String {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<User>=User.fetchRequest()
        request.returnsObjectsAsFaults = false
        var ret = "No User"
        do {
            let results = try context.fetch(request)
            for item in results {
                ret =  item.userID!
            }
        }catch {
            print("Could not find stats. \(error)")
        }
        if ret == "" { ret = "No User" }
        return ret
    }
    /// Return current user's userID as a string from the device
    /// - Returns: User's ID
    class func getCurrentUserID() -> String {
        var ID = ""
        var x = 0
        DispatchQueue.main.async {
            ID = returnCurrentUsersID()
            x = 1
        }
        while x == 0 {
        }
        return ID
    }
    
    /// Return the current User as a NSManagedObject
    /// - Returns: User's NSManagedObject
    class func returnCurrentUser() -> User {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<User>=User.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            for user in results {
                return user
            }
        }catch {
            print("Could not find User. \(error)")
        }
        let userEntity = NSEntityDescription.entity(forEntityName: "User", in: context)
        let nothing = NSManagedObject(entity: userEntity!, insertInto: context)as! User
        return nothing as User
    }

    /// Delete all Users and Sessions from Core Data
    class func deleteData() -> Void {
        // Get context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        self.UDID = ""
        self.DBuser = "No User"
        self.lastSynced = "Never"
        
        // Create the fetch requests
        let userRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        let sessionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")
        
        // Create the delete requests
        let userDeleteRequest = NSBatchDeleteRequest(fetchRequest: userRequest)
        let sessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: sessionRequest)
        let persistentStoreCoordinator = context.persistentStoreCoordinator!
        
        do {
            // Delete the sessions and then the Users
            try persistentStoreCoordinator.execute(sessionDeleteRequest, with: context)
            try persistentStoreCoordinator.execute(userDeleteRequest, with: context)
            
            // Save the changes
            try context.save()
        } catch let error as NSError {
            debugPrint(error)
        }
    }
    
    /// Delete all sessions from Core Data
    class func overwriteSessions() -> Void {
        // Get context
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        // Create the fetch request
        let sessionRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Session")
        
        // Create the delete request
        let sessionDeleteRequest = NSBatchDeleteRequest(fetchRequest: sessionRequest)
        let persistentStoreCoordinator = context.persistentStoreCoordinator!
        
        do {
            // Delete the sessions
            try persistentStoreCoordinator.execute(sessionDeleteRequest, with: context)
            
            // Save the changes
            try context.save()
        } catch let error as NSError {
            debugPrint(error)
        }
    }
    
    /// Return number of users in Core Data
    /// - Returns: Number of users in core data
    class func numberOfUsers() -> Int {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<User>=User.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            return results.count
        }
        catch let error as NSError {
            debugPrint(error)
            return -1
        }
    }
    
    /// Return number of Sessions in Core Data
    /// - Returns: Number of sessions
    class func numberOfSessions() -> Int {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Session>=Session.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            return results.count
        }
        catch let error as NSError {
            debugPrint(error)
            return -1
        }
    }
    
    /// Get the target intensity for specific user from the Database
    /// - Postcondition: Target intensity is saved to Core Data.
    class func updateTargetIntensity() {
        
        // Create urlstr string with current userID
        let urlstr : String = Util.getHOST() + "Restful/getTargetIntensity.php?pmkPatientID="
            + Util.returnCurrentUsersID()
        
        // Make url string into actual url and catch errors
        guard let url = URL(string: urlstr)
            else {
                print("Error: cannot create URL")
                return
        }
        
        // Creates urlRequest using our url
        let urlRequest = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If data exists, grab it and set it to our global variable
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                }
                catch {
                    return
                }
                if let targetIntensity = jo["fldGoal"] {
                    let returnedTargetIntensity = (targetIntensity as! NSString)
                    
                    // Send the target intensity to the saveTargetIntensity function to save to Core Data
                    saveTargetIntensity(returnedTargetIntensity: returnedTargetIntensity as String)
                }
            }
        })
        // Resume the URL Request task
        task.resume()
    }
    
    /// Save target intensity to Core Data
    /// - Parameter returnedTargetIntensity: Target intensity retrieved from the database
    class func saveTargetIntensity(returnedTargetIntensity: String) {
        DispatchQueue.main.async(execute: {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest< User >=User.fetchRequest()
        request.returnsObjectsAsFaults = false
        
        do {
            // Make the fetch request
            let coreUser = try context.fetch( request  )
            
            for user in coreUser {
                user.targetIntensity = returnedTargetIntensity
            }
        }catch {
            print("Could not find users. \(error)")
        }
        
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    })
    }
    
    /// Return the target intensity from core data
    /// - Returns: Target intensity
    class func returnTargetIntensity() -> Double {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<User>=User.fetchRequest()
        request.returnsObjectsAsFaults = false
        do {
            let results = try context.fetch(request)
            for item in results {
                let stringTargetIntensity = item.targetIntensity!
                let targetIntensity: Double = Double( stringTargetIntensity )!
                return targetIntensity
            }
        }catch {
            print("[ERROR] Could not find stats. \(error)")
            return 0.0
        }
        return 0.0
    }
    
    /// Read data from a CSV file given the fileName as a parameter
    /// - Parameter file: Any CSV file
    class func readDataFromFile(file: String) {
        let fileName = file
        let docDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if let fileURL = docDirectory?.appendingPathComponent(fileName).appendingPathExtension("csv") {
            do {
                print("[DEBUG] Attempting to read from file!")
                let db = try String(contentsOf: fileURL)
                let lines:[String] = db.components(separatedBy: "\n") as [String]
                for line in lines{
                    print(line)
                }
            } catch {
                print("File Read Error for file")
            }
        }
    }
    
    /// Return a random String that is the positive feedback for the user
    /// - Returns: positive feedback at the random index of the array
    class func getPositiveFeedback() -> String {
        // List of positive feedback from Dr. Toth
        let positiveFeedback = ["Good job completing your NMES session!",
                                "By completing your NMES session, you are preventing your muscles from atrophying andgetting weaker.",
                                "Completing your NMES sessions is like putting money in the bank. It will pay off in larger, stronger muscles so you can get back to your activities faster.",
                                "By completing your NMES session, you are being proactive in preventing muscle atrophy and maintaining your muscle strength.",
                                "The 60 min you just spent doing NMES on your leg is keeping your muscles healthy.",
                                "The Research Team says “congrats” for finishing your NMES session.",
                                "NMES is FDA approved to help your muscles after injury and surgery. Keep up the good work!",
                                "Keep up the good work on your NMES sessions!",
                                "Each NMES session that you complete is another step closer to getting you back on your feet.",
                                "Nice work on the NMES session. Contact the research team if you have any questions.",
                                "Nice to see that you’re using up electrode pads on those NMES sessions. Contact the research team if you need more or have any questions.",
                                "We like to see the batteries of your NMES device drain like that! Good work finishing your session.",
                                "Great job finishing your NMES session!",
                                "Another NMES session completed. You’re helping your muscles stay strong!",
                                "Doing NMES now is like starting the rehab on your muscles early. Good work!",
                                "The NMES sessions you’re completing now help maintain your muscles so you can get back to your activities sooner after your surgery."]
        
        // Return the positive feedback at the random index of the array
        return positiveFeedback[random(max: positiveFeedback.count)]
    }
    
    /// Return a random int in a specific range
    /// - Parameter max (maxNumber): The maximum integer of a specific range
    /// - Returns: A random integer
    class func random(max maxNumber: Int) -> Int {
        return Int(arc4random_uniform(UInt32(maxNumber)))
    }
    
    /// Return the average of an array of doubles
    /// - Parameter array: An array of doubles
    /// - Returns: A double value
    class func average(array: [Double]) -> Double {
        var sum = 0.0
        for number in array {
            sum += number
        }
        let ave = sum / Double(array.count)
        return ave
    }
    /// Set user's device ID
    /// - Parameter udid: User's device ID
    class func setUDID(udid: String){
        UDID = udid;
    }
    /// Return user's device ID
    /// - Returns: User's device ID
    class func getUDID() -> String{
        return UDID;
    }
    /// Return the date when last sync occurs
    /// - Returns: A list of lastSynced and numSessions
    class func getDeviceLastSynced() -> [String] {
        lastSynced = "Never"
        numSessions = "0 "
            findDeviceLastSynced()
        while(lastSynced == "Never" || numSessions == "0 "){
        }
            return [lastSynced, numSessions];
    }
    /// Set global variables with the information of last synced
    class func findDeviceLastSynced(){
        // Create urlstr string with current userID
        let urlstr : String = Util.getHOST() + "Restful/getDeviceSync.php?pmkPatientID=" + Util.returnCurrentUsersID()
        
        // Make url string into actual url and catch errors
        guard let url = URL(string: urlstr)
            else {
                print("Error: cannot create DLS url")
                print(urlstr)
                lastSynced = "Never!"
                numSessions = "0"
                return
        }
        
        // Creates urlRequest using our url
        // Let urlRequest = NSMutableURLRequest(url: url)
        var urlRequest = URLRequest(url: url)
        print(urlstr)
        var task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If data exists, grab it and set it to our global variable
            print(error == nil)
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo =
                        try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                    print(jo)
                }
                catch {
                    lastSynced = "  "
                    numSessions="0"
                    return
                }
                if let name = jo["sync"] as? String {
                     lastSynced = name
                }
                else{
                    lastSynced = "Never "
                }
                if let num = jo["count"] as? String {
                    numSessions = num
                }
                else{
                    numSessions = "0"
                }
            }
            else {
                print(error)
                lastSynced = "  "
                numSessions="0"
            }
        })
        task.resume()
    }

    /// Return patient's ID for database
    /// - Returns: Patient's ID for database
    class func getDatabaseUsername() -> String {
        let serialQueue = DispatchQueue(label: "queuename")
        var x = 0
        try serialQueue.sync{
            findDatabaseUsername(finished: { string in
                self.DBuser = string
                x = 1
            })
        }
        while (x==0){
            
        }
        return self.DBuser
    }
    /// Set global variables with the information of the patient
    class func findDatabaseUsername(finished: @escaping ((_: String)->Void)) {
        
        // Create urlstr string with current userID
        var uname :String!
        let urlstr : String = Util.getHOST() + "Restful/example.php?pmkPatientID=" + Util.returnCurrentUsersID()
        
        // Make url string into actual url and catch errors
        guard let url = URL(string: urlstr)
            else {
                print("Error: cannot create URL1")
                finished(_ : "No User!")
                return
        }
        
        // Creates urlRequest using our url
        // Let urlRequest = NSMutableURLRequest(url: url)
        var urlRequest = URLRequest(url: url)
        print(urlstr)
        var task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If data exists, grab it and set it to our global variable
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo =
                        try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                    print(jo)
                }
                catch {
                    finished(_ : "No User!")
                    return
                }
                if let name = jo["pmkPatientID"] {
                        finished(_ : name as! String)
                    print("This: ",self.DBuser)
                }
            }
            else {
                finished(_ : "No User!")
                print(error)
            }
        })
        // Return value of returnedUserID
        task.resume()
    }
    /// Return the status of push notification registration
    /// - Returns: A string representing registration status
    class func pushRegistration() -> String {
    
        let earl = Util.getHOST() + "Restful/restful.php"
        var urlRequest: URLRequest
        guard let url2 = URL(string: earl)
            else {
                print("Error: cannot create URL")
                return "URL creation failed"
            }
        do{
            urlRequest = URLRequest(url: url2 as URL)
        }
        catch{
            print("error can't create URL")
            return "URL creation failed"
        }
        urlRequest.httpMethod = "POST"
        let json: [String: Any] = [
            "pmkPatientID": Util.returnCurrentUsersID(),
            "UDID": Util.getUDID()
        ]
        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: json, options: [])
        } catch let error {
            print(error.localizedDescription)
        }
    
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If data exists, grab it and set it to our global variable
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo = try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                }
                catch {
                    return
                }
                if let success = jo["success"] {
                    if  success as!  Bool{
                        print("push notification registration successful!")
                    }
                else{
                    print("push notification registration failed:")
                    print(jo["error"])
    
                }
            }
        }
    })
    // Return value of returnedUserID
    task.resume()
    return "success"
    }
}
