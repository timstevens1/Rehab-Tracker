//
//  SyncViewController.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 11/2/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//
// Need to give website props for the tab bar icon
// <a href="https://icons8.com">Icon pack by Icons8</a>
//

// The purpose of this file is to pull data from the device and sync to core data and db

// Reference: 12 steps of bluetooth
// Kevin Hoyt
// http://www.kevinhoyt.com/2016/05/20/the-12-steps-of-bluetooth-swift/


// (1) Import
// Unlike beacons, which use Core Location, if you are communicating to a BLE device, you will use CoreBluetooth.
import Foundation
import UIKit
import CoreData
import CoreBluetooth

// DEBUG mode flag
let DEBUG = true

// Switch for including session time tracking (start time, end time)
let SESSION_TIME_TRACKING = true

// Last session number for this user
var maxUserSessionNum:Int? = nil

// String to hold session info received from device
var sessionsStringFromDevice = ""

// Set of positive feedback messages for successful sync alert
let positiveFeedbackMessages = ["By completing your NMES session, you are preventing your muscles from atrophying and getting weaker.", "Good job completing your NMES session!", "Keep up the good work on your NMES sessions!", "By completing your NMES session, you are being proactive in preventing muscle atrophy and maintaining your muscle strength."]

// (2) Delegates
// Eventually you are going to want to get callbacks from some functionality. There are two delegates to implement: CBCentralManagerDelegate, and CBPeripheralDelegate.
class SyncViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    //(3) Declare Manager and Peripheral
    // The CBCentralManager install will be what you use to find, connect, and manage BLE devices. Once you are connected, and are working with a specific service, the peripheral will help you iterate characteristics and interacting with them.
    private var manager:CBCentralManager!
    private var peripheral:CBPeripheral!
    private var resultString: String!
    private var stats:[(avg_ch1_intensity:String, avg_ch2_intensity:String, session_compliance: String, start_time: String, end_time: String)] = []
    private var failed_sync = false
    private var feedback_message:String = ""
    private var finished_parsing_data = false
    
    // (4) UUID and Service Name
    // You will need UUID for the BLE service, and a UUID for the specific characteristic. In some cases, you will need additional UUIDs. They get used repeatedly throughout the code, so having constants for them will keep the code cleaner, and easier to maintain.
    let RT_NAME = "RT"
    let RT_SERVICE_UUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    let RT_CHAR_TX_UUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
    let RT_CHAR_RX_UUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
    
    var flag = false
    
    // global variable comments to store session comments
    private var comments = "No Comments"
    
    // Sync image outlet
    @IBOutlet weak var sync_image: UIImageView!
    
    // Sync button outlet
    @IBOutlet weak var sync_button: UIButton!
    
    // Empty dictionary to hold JSON for post to database
    private var sessionsJson = [String: [String:Any]]()
    
    @IBAction func showInfo(_ sender: UIBarButtonItem) {
        // create the alert
        let alert = UIAlertController(title: "Problems?", message: "Make sure your device is in range and paired with your phone!", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    // Reset sync UI and create post-sync alert - feedback on success or failure
    private func syncResetUIAndFeedbackAlert() {
        // Reset image and button
        self.sync_image.stopAnimating()
        self.sync_image.image = UIImage(named: "Tab-Sync-Highlighted")
        self.sync_button.isEnabled = true
        self.sync_button.setTitle("Sync", for: .normal)
        // Create sync feedback alert
        var alert_title = "Success!"
        if (self.failed_sync) {
            alert_title = "Sync Failed"
        }
        let post_sync_alert = UIAlertController(title: alert_title, message: feedback_message, preferredStyle: UIAlertControllerStyle.alert)
        // OK button on alert box
        post_sync_alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: { (action:UIAlertAction) -> Void in
            self.sync_image.image = UIImage(named: "Tab-Sync")}))
        // Show sync feedback alert
        self.present(post_sync_alert, animated: true, completion: nil)
    }
    
    @IBAction func Sync(_ sender: UIButton) {
        // Alert to take input and save it
        let alert = UIAlertController(title: "Comments",
                                      message: "Please enter comments on your previous training sessions!",
                                      preferredStyle: .alert)
        
        // Creates the save button in the alert
        let saveAction = UIAlertAction(title: "Continue",
                                       style: .default,
                                       handler: { (action:UIAlertAction) -> Void in
                                        
                                        // Save input
                                        let textField = alert.textFields!.first
                                        self.comments = textField!.text!
                                        
                                        // Set failure flag to false - nothing wrong yet
                                        self.failed_sync = false
                                        
                                        // Update sync button and animate image
                                        self.sync_button.isEnabled = false
                                        self.sync_button.setTitle("...", for: .normal)
                                        var imageList = [UIImage]()
                                        let image1:UIImage = UIImage(named: "Tab-Sync-Highlighted")!
                                        let image2:UIImage = UIImage(named: "Tab-Sync")!
                                        imageList = [image1, image2];
                                        self.sync_image.animationImages = imageList
                                        self.sync_image.animationDuration = 1.0
                                        self.sync_image.startAnimating()
                                        
                                        // Reset sessionsString
                                        sessionsStringFromDevice = ""
                                       
                                        do {
                                            if self.flag == true {
                                                if self.manager.state != .poweredOn {
                                                    print("[ERROR] Couldn´t disconnect from peripheral")
                                                }
                                                else if self.peripheral != nil{
                                                    print("[DEBUG] Disconnecting from the BLE")
                                                    self.manager.cancelPeripheralConnection(self.peripheral!)
                                                }
                                            }
                                            
                                            // (5) Instantiate Manager
                                            // One-liner to create an instance of CBCentralManager. It takes the delegate as an argument, and options, which in most cases are not needed. This is also the jumping off point for what effectively becomes a chain of the remaining seven waterfall steps.
                                            self.manager = CBCentralManager (delegate: self, queue: nil)
                                            
                                            self.flag = true;
                                            
                                            // Timeout if data not correctly synced from NMES device after 10 seconds
                                            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0, execute: {
                                                if (sessionsStringFromDevice == "" || !sessionsStringFromDevice.contains("\n") || !self.finished_parsing_data) {
                                                    self.failed_sync = true
                                                    self.feedback_message = "Error finding data on NMES device. Please reboot your NMES device and try again."
                                                    print("[DEBUG] Problem syncing data from NMES device")
                                                    self.syncResetUIAndFeedbackAlert()
                                                }
                                            })
                                            
                                            // see what's in core data - DEBUG STEP
                                            /*let appDelegate = UIApplication.shared.delegate as! AppDelegate
                                            let context = appDelegate.persistentContainer.viewContext
                                            let request: NSFetchRequest<Session> = Session.fetchRequest()
                                            request.returnsObjectsAsFaults = false
                                            
                                            do {
                                                let cd_sessions = try context.fetch(request)
                                                print("ALL SESSIONS IN CORE DATA:") //DEBUG STEP
                                                for val in cd_sessions {
                                                    // Assign values for post variables
                                                    let num = val.sessionID!
                                                    print("FLD_SESS_NUM") //DEBUG STEP
                                                    print(num)
                                                }
                                                
                                            }catch {
                                                // Sync Error Alert
                                                self.syncErrorAlert()
                                                
                                                print("Could not find stats. \(error)")
                                            }*/
                                            
                                            // LOCAL TESTING
                                            /*
                                            self.resultString = ""
                                            sessionsStringFromDevice = "90,90,0.10,1513027000,1513027272\n93,93,0.99,1513027272,1513027500\n"
                                            
                                            print("SESSIONS_STRING_FROM_DEVICE")
                                            print(sessionsStringFromDevice)
                                            if (sessionsStringFromDevice.hasSuffix("\n")) {
                                                // Set feedback message to positive message
                                                let randomPositiveMessageIndex = Int(arc4random_uniform(UInt32(positiveFeedbackMessages.count)))
                                                self.feedback_message = positiveFeedbackMessages[randomPositiveMessageIndex]
                                                self.parseData()
                                                print("DATA PARSED")
                                                // It no failure yet, sync sessions to core data and db
                                                if (!self.failed_sync) {
                                                    self.syncSessions()
                                                    print("SESSIONS SYNCED")
                                                    // If failure in parseData(), update error message and launch alert
                                                } else {
                                                    self.feedback_message = "Error syncing data from NMES device. Please reboot your NMES device and try again."
                                                    self.syncResetUIAndFeedbackAlert()
                                                    return
                                                }
                                                // Reset sync UI and launch feedback alert
                                                self.syncResetUIAndFeedbackAlert()
                                            }*/
                                        }
        })
        
        // textfield for input
        alert.addTextField {(textField: UITextField) -> Void in}
        alert.addAction(saveAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // Get and set current date for fldDeviceSynced
    private func thisDate() -> String {
        let currDate = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: currDate)
    }
    
    // Convert unix time (seconds - this is format sent by Arduino) to datetime format
    private func unixSecondsToDatetime(seconds_since_1970:Int32) -> String {
        if (!SESSION_TIME_TRACKING) {
            return "0000-00-00 00:00:00"
        }
        let datetime = Date(timeIntervalSince1970: Double(seconds_since_1970))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: datetime)
    }
    
    // Parse sessionsStringFromDevice to extract session info
    private func parseData() {
        do {
            // New sessions string to array
            var newSessions = sessionsStringFromDevice.components(separatedBy: "\n")
            newSessions.remove(at: newSessions.count-1)
            print("NEW SESSIONS COUNT")
            print(newSessions.count)
            
            // Data array for each session - append each session data array to stats array
            for session in newSessions{
                
                let myDataArr = session.components(separatedBy: ",")
                
                // Get the first character of the data string which is the session Count to make sure no duplicated
                //let index = session.index(session.startIndex, offsetBy: 0)
                
                // Check if the array contains correct number of data points
                if ((SESSION_TIME_TRACKING && myDataArr.count == 5) || (!SESSION_TIME_TRACKING && myDataArr.count == 3)) {
                    let sess_start_time = SESSION_TIME_TRACKING ? myDataArr[3] : "0"
                    let sess_end_time = SESSION_TIME_TRACKING ? myDataArr[4] : "0"
                    // Add validated data to stats array
                    let stat = (avg_ch1_intensity:myDataArr[0], avg_ch2_intensity:myDataArr[1], session_compliance: myDataArr[2], start_time:sess_start_time, end_time:sess_end_time)
                    self.stats.append(stat)
                } else {
                    print("[DEBUG] Invalid Data/Duplicate session:")
                    for data in myDataArr {
                        print(data)
                    }
                    // failure
                    failed_sync = true
                    print("end data in myDataArr")
                }
                print("STATS")
                print(self.stats)
                print("STATS COUNT")
                print(self.stats.count)
            }
            // Clear out the resultString once we have the data to prevent duplication
            resultString.removeAll()
            // Set flag for finished parsing data from NMES device
            self.finished_parsing_data = true
        }
        /*
         catch let error as NSError {
         // Sync Error Alert
         self.syncErrorAlert()
         }
         */
    }
    
    // Add parsed sessions to core data (via call to addData()) and database (via call to pushToDatabase())
    private func syncSessions() {
        /* First, get max session number for this user from db
         Use this to determine new session numbers */
        // Create urlstr string with current userID
        let urlstr : String = Util.getHOST() + "Restful/sync.php?pmkPatientID=" + Util.returnCurrentUsersID()
        // Make url string into actual url
        let url = URL(string: urlstr)
        // Create urlRequest using our url
        let urlRequest = URLRequest(url: url!)
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If number of last user session exists, grab it and set it to our variable
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo =
                        try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                    print(jo)
                }
                catch {
                    return
                }
                maxUserSessionNum = jo.value(forKey: "maxUserSessionNumber") as! Int
                print("MAX_USER_SESS_NUM_IN_DB")
                print(maxUserSessionNum)
            }
            else {
                print(error as! String)
                self.failed_sync = true
                self.feedback_message = "Error determining session number. Please try again."
            }
            if (maxUserSessionNum == nil) {
                self.failed_sync = true
                self.feedback_message = "Error determining session number. Please try again."
            }
            /* Add sessions to core data and database */
            DispatchQueue.main.async {
                if (!self.failed_sync) {
                    self.addData()
                }
                // see what's in core data - DEBUG STEP
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                let request: NSFetchRequest<Session> = Session.fetchRequest()
                request.returnsObjectsAsFaults = false
                do {
                    let cd_sessions = try context.fetch(request)
                    print("ALL SESSIONS IN CORE DATA:") //DEBUG STEP
                    for val in cd_sessions {
                        let num = val.sessionID!
                        print("FLD_SESS_NUM") //DEBUG STEP
                        print(num)
                    }
                } catch {
                    print("Could not find stats. \(error)")
                }
                if (!self.failed_sync) {
                    self.prepareNewSessionsJSON()
                }
                if (!self.failed_sync) {
                    self.pushToDatabase()
                }
            }
        })
        task.resume()
    }
    
    // Save sessions in core data
    private func addData() {
        var current_session_id = maxUserSessionNum!
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let sesEntity = NSEntityDescription.entity(forEntityName: "Session", in: context)
        print("NEW SESSIONS TO SAVE TO CORE DATA:") //DEBUG STEP
        for stat in stats {
            print("in the loop")
            current_session_id = current_session_id + 1
            let session = NSManagedObject(entity: sesEntity!, insertInto: context)as! Session
            session.sessionID = String(current_session_id)
            print(current_session_id) //DEBUG STEP
            session.session_compliance = stat.session_compliance
            session.avg_ch1_intensity = stat.avg_ch1_intensity
            session.avg_ch2_intensity = stat.avg_ch2_intensity
            session.start_time = Int32(stat.start_time)!
            session.end_time = Int32(stat.end_time)!
            session.pushed_to_db = false
            //session.notes = self.comments
            session.hasUser = Util.returnCurrentUser()
        }
        print("after the loop")
        (UIApplication.shared.delegate as! AppDelegate).saveContext()
    }

    // Retrieve new session info from core data and prepare JSON object for db push
    private func prepareNewSessionsJSON() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "pushed_to_db == false")
        request.returnsObjectsAsFaults = false
        
        do {
            let sessions = try context.fetch(request)
            print("sessions");
            print(sessions);
            print("SESSIONS RETRIEVED FROM CORE DATA:") //DEBUG STEP
            // Populate json object with data for post
            var i = 0;
            for session in sessions {
                let key = String(i)
                let thisSessionJsonObject: [String: [String:Any]] = [
                    key : ["fldSessNum" : session.sessionID!,
                         "fldSessionCompliance" : session.session_compliance,
                         "fldIntensity1" : session.avg_ch1_intensity!,
                         "fldIntensity2" : session.avg_ch2_intensity!,
                         "fldStartTime" : unixSecondsToDatetime(seconds_since_1970: session.start_time),
                         "fldEndTime" : unixSecondsToDatetime(seconds_since_1970: session.end_time),
                         "fldNote" : self.comments,
                         "fldDeviceSynced" : self.thisDate(),
                         "pmkPatientID" : Util.returnCurrentUsersID()
                        ]
                ]
                print("FLD_SESS_NUM") //DEBUG STEP
                print(session.sessionID!) //DEBUG STEP
                sessionsJson.merge(thisSessionJsonObject) { (current, _) in current }
                let valid = JSONSerialization.isValidJSONObject(sessionsJson)
                print("valid json?")
                print(valid)
                i += 1
            }
            print("sessionsJson")
            print(sessionsJson)
            
        } catch {
            // failure
            self.failed_sync = true
            self.feedback_message = "Error finding new session data on phone. Please try again."
            print("Could not find new sessions. \(error)")
        }
    }
    
    // Push new sessions to database via JSON object
    private func pushToDatabase() {
        let urlstr : String = Util.getHOST() + "Restful/sync.php"
        
        //Make url string into actual url and catch errors
        guard let url = URL(string: urlstr)
            else {
            // failure
            self.failed_sync = true
            self.feedback_message = "Error linking to network. Please try again."
            print("Error: cannot create URL")
            return
        }
        
        // Creates urlRequest using our url
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: sessionsJson, options: [])
        } catch let error {
            self.feedback_message = "Error linking to network. Please try again."
            print(error.localizedDescription)
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler:{
            (data, response, error) in
            if error != nil {
                // Sync Error Alert
                self.failed_sync = true
                self.feedback_message = "Error syncing sessions to network. Please try again."
                print("[ERROR] There was an error with the URL/Sync")
                return;
            }
        })
        
        task.resume()
        
        print("before pushed_to_db flag set")
        // Update pushed_to_db flag to true in core data for saved sessions
        for session in sessionsJson {
            // Set up fetch request for core data object of pushed session
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request: NSFetchRequest<Session> = Session.fetchRequest()
            print("fldSessNum before predicate")
            print(session.1["fldSessNum"]!)
            request.predicate = NSPredicate(format: "sessionID == %@", session.1["fldSessNum"]! as! CVarArg)
            // Execute request and update pushed_to_db to true
            do {
                let pushedSession = try context.fetch(request) // list of one session
                if pushedSession.count != 1 { // count != 1 for this session id in core data
                    print("count != 1 for sessionID in core data")
                }
                for session in pushedSession {
                    session.setValue(true, forKey: "pushed_to_db")
                }
                (UIApplication.shared.delegate as! AppDelegate).saveContext()
                print("UPDATE PUSHED TO DB FOR SESS:")
                print(session.1["fldSessNum"])
            }
            catch {
                print("Update pushed_to_db field failed")
            }
        }
    }
    
    // (6) Scan for Devices
    // Once the CBCentralManager instance is finished creating, it will call centralManagerDidUpdateState on the delegate class. From there, if Bluetooth is available (as in "turned on"), you can start scanning for devices.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print("[DEBUG] CentralManager is initialized")
        
        switch central.state {
        case .poweredOn:
            print("[DEBUG] Central manager state: Powered on")
            break
        case .poweredOff:
            print("[DEBUG] Central manager state: Powered off")
            break
        case .unauthorized:
            print("[DEBUG] Central manager state: Unauthorized")
            break
            
        default: break
        }
        
        if central.state == .poweredOn {
            //Scan for devices
            //central.scanForPeripherals(withServices: nil, options: nil)
            //print(central.scanForPeripherals(withServices: nil, options: nil))
            
            central.scanForPeripherals(withServices: [RT_SERVICE_UUID], options: nil)
            
            
            
        } else {
            print("[DEBUG] Bluetooth not available.")
            self.failed_sync = true
            self.feedback_message = "Bluetooth is not enabled."
            self.syncResetUIAndFeedbackAlert()
        }
    }
    
    // (7) Connect to a Device
    // When you find the device you are interested in interacting with, you will want to connect to it. This is the only place where the device name shows up in the code, but I still like to declare it as a constant with the UUIDs.
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        
        print("[DEBUG] Looking for the device and trying to connect.")
        
        print("[DEBUG] Found the device: ", peripheral.identifier.uuidString)
        self.manager.stopScan()
        
        self.peripheral = peripheral
        self.peripheral.delegate = self
        
        manager.connect(peripheral, options: nil)
        
        
        //If there are multiple devices, we can use RT_NAME to recognize the specific device
        
        /*
         let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey)as? NSString
         
         
         if device?.contains(RT_NAME) == true {
         print("[DEBUG] Found the device.")
         self.manager.stopScan()
         
         self.peripheral = peripheral
         self.peripheral.delegate = self
         
         manager.connect(peripheral, options: nil)
         }
         else{
         print("No")
         
         }
         */
    }
    
    // (8) Get Services
    // Once you are connected to a device, you can get a list of services on that device.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("[DEBUG] Connected to the device and discovering services.")
        peripheral.discoverServices(nil)
    }
    
    // (9) Get Characteristics
    // Once you get a list of the services offered by the device, you will want to get a list of the characteristics.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        print("[DEBUG] Geting a list of characteristics.")
        for service in peripheral.services! {
            print("[DEBUG] In one of the services:")
            let thisService = service as CBService
            
            if service.uuid == RT_SERVICE_UUID {
                print("[DEBUG] In this service:")
                
                peripheral.discoverCharacteristics(nil, for: thisService)
                //peripheral.discoverCharacteristics([RT_CHAR_TX_UUID], for: thisService)
            }
        }
    }
    
    // (10) Setup Notifications
    // There are different ways to approach getting data from the BLE device. One approach would be to read changes incrementally. Another approach, the approach I used in my application, would be to have the BLE device notify you whenever a characteristic value has changed.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("[DEBUG] Setup notifications.")
        
        //let data: NSData = "R".data(using: String.Encoding.utf8)! as NSData
        /*
         var flag = true;
         */
        let data = NSData(bytes: &flag, length: MemoryLayout<Bool>.size)
        
        
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == RT_CHAR_TX_UUID {
                self.peripheral.setNotifyValue(true, for: thisCharacteristic)
            }
            else if thisCharacteristic.uuid == RT_CHAR_RX_UUID {
                print("rx")
                if flag == true{
                    // Write true to the Blend so it knows app is ready to receive data
                    peripheral.writeValue(data as Data, for: characteristic, type: CBCharacteristicWriteType.withoutResponse)
                }
            }
            
        }
    }
    
    // (11) Changes Are Coming
    // Any characteristic changes you have setup to receive notifications for will call this delegate method. You will want to be sure and filter them out to take the appropriate action for the specific change.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        
        print("[DEBUG] Characteristic is changed.")
        //var count:UInt32 = 0;
        
        if characteristic.uuid == RT_CHAR_TX_UUID {
            
            //print(characteristic.value!)
            //print(NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)!)
            
            let resultNSString = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)!
            //let resultString = resultNSString as String
            
            resultString = resultNSString as String
            
            print(resultString)
            
            print("[DEBUG] Changing the text: ", NSString(format: "%llu", resultString) as String)
            
            sessionsStringFromDevice = sessionsStringFromDevice + resultString
            
            print("SESSIONS_STRING_FROM_DEVICE")
            print(sessionsStringFromDevice)
            if (sessionsStringFromDevice.hasSuffix("\n")) {
                // Set feedback message to positive message
                let randomPositiveMessageIndex = Int(arc4random_uniform(UInt32(positiveFeedbackMessages.count)))
                feedback_message = positiveFeedbackMessages[randomPositiveMessageIndex]
                parseData()
                print("DATA PARSED")
                // It no failure yet, sync sessions to core data and db
                if (!self.failed_sync) {
                    syncSessions()
                    print("SESSIONS SYNCED")
                // If failure in parseData(), update error message and launch alert
                } else {
                    feedback_message = "Error syncing data from NMES device. Please reboot your NMES device and try again."
                    self.syncResetUIAndFeedbackAlert()
                    return
                }
                // Reset sync UI and launch feedback alert
                self.syncResetUIAndFeedbackAlert()
            }
            
            //flag = false
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.sync_image.image = UIImage(named: "Tab-Sync")
        flag = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
