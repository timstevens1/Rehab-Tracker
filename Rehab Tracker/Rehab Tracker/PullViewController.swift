//
//  PullViewController.swift
//  Rehab Tracker
//
//  Created by Chia-Chun Chao on 11/2/17.
//  Copyright © 2017 CS 275 Project Group 6. All rights reserved.
//


// 12 steps of bluetooth
// Kevin Hoyt
// http://www.kevinhoyt.com/2016/05/20/the-12-steps-of-bluetooth-swift/


// (1) Import
// Unlike beacons, which use Core Location, if you are communicating to a BLE device, you will use CoreBluetooth.
import Foundation
import UIKit
import CoreData
import CoreBluetooth

// Switch for including session time tracking (start time, end time)
// TO DO: Switch to true once real-time clock is implemented and timing data can be sent to app
// TO DO: Consolidate with SVC - only one switch should be used
let SESSION_TIME_TRACKING_PVC = false

// Last session number for this user
var maxUserSessionNum = 0 // If no user sessions, start with 0

// (2) Delegates
// Eventually you are going to want to get callbacks from some functionality. There are two delegates to implement: CBCentralManagerDelegate, and CBPeripheralDelegate.
class PullViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //(3) Declare Manager and Peripheral
    // The CBCentralManager install will be what you use to find, connect, and manage BLE devices. Once you are connected, and are working with a specific service, the peripheral will help you iterate characteristics and interacting with them.
    private var manager:CBCentralManager!
    private var peripheral:CBPeripheral!
    var resultString: String!
    private var stats:[(avg_ch1_intensity:String, avg_ch2_intensity:String, session_compliance: String, start_time: String, end_time: String)] = []

    // (4) UUID and Service Name
    // You will need UUID for the BLE service, and a UUID for the specific characteristic. In some cases, you will need additional UUIDs. They get used repeatedly throughout the code, so having constants for them will keep the code cleaner, and easier to maintain.
    let RT_NAME = "RehabTracker"
    let RT_SERVICE_UUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
    let RT_CHAR_TX_UUID = CBUUID(string: "713D0002-503E-4C75-BA94-3148F18D941E")
    let RT_CHAR_RX_UUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E")
    
    
    
    
    @IBOutlet weak var textTransfer: UITextView!
    // Label
    @IBOutlet weak var lblTransfer: UILabel!
    // Button
    @IBAction func btnScan(_ sender: Any) {
        print("!!!!!!!!!!!!!!!!!!!!")
        lblTransfer.text="Hello"
        //parseData() //FOR LOCAL TESTING
        // (5) Instantiate Manager
        // One-liner to create an instance of CBCentralManager. It takes the delegate as an argument, and options, which in most cases are not needed. This is also the jumping off point for what effectively becomes a chain of the remaining seven waterfall steps.
        manager = CBCentralManager (delegate: self, queue: nil)
        
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
        }
    }
    
    // (7) Connect to a Device
    // When you find the device you are interested in interacting with, you will want to connect to it. This is the only place where the device name shows up in the code, but I still like to declare it as a constant with the UUIDs.
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        
        
        print("[DEBUG] Looking for the device and trying to connect.")
        
        //let device = (advertisementData as NSDictionary).object(forKey: CBAdvertisementDataLocalNameKey)as? NSString
        
        
        print("[DEBUG] Found the device: ", peripheral.identifier.uuidString)
        self.manager.stopScan()
            
        self.peripheral = peripheral
        self.peripheral.delegate = self
            
        manager.connect(peripheral, options: nil)
        
        
        /*
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
        for characteristic in service.characteristics! {
            let thisCharacteristic = characteristic as CBCharacteristic
            
            if thisCharacteristic.uuid == RT_CHAR_TX_UUID {
                self.peripheral.setNotifyValue(true, for: thisCharacteristic)
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
            
            
            //characteristic.value!.getBytes(&count, length: sizeof(UInt32))
            
            //lblTransfer.text = NSString(format: "%llu", resultString) as String
            lblTransfer.text = resultString
            textTransfer.text = resultString
            parseData()
        }
    }
    
    private func parseData() {
            do {
            //resultString = "85,85,0.95\n92,92,0.65" //FOR LOCAL TESTING
            // Create an array to track which sessions weve synced
            var sessionsAdded = [Character]()
            let newSessions = resultString.components(separatedBy: "\n")

            
            // First break up the data array by newlines to seperate out each session
            for session in newSessions{
                
                let myDataArr = session.components(separatedBy: ",")
                
                // Get the first character of the data string which is the session Count to make sure no duplicated
                //let index = session.index(session.startIndex, offsetBy: 0)
                
                // Check if the array contains correct number of data points
                if ((SESSION_TIME_TRACKING_PVC && myDataArr.count == 5) || (!SESSION_TIME_TRACKING_PVC && myDataArr.count == 3)) {
                    let sess_start_time = SESSION_TIME_TRACKING_PVC ? myDataArr[3] : "0"
                    let sess_end_time = SESSION_TIME_TRACKING_PVC ? myDataArr[4] : "0"
                    // Add validated data to stats array
                    let stat = (avg_ch1_intensity:myDataArr[0], avg_ch2_intensity:myDataArr[1], session_compliance: myDataArr[2], start_time:sess_start_time, end_time:sess_end_time)
                    self.stats.append(stat)
                    //sessionsAdded.append(session[index]);
                    // append the session_compliance to the array for calculating if we should give feedback
                    let compDouble = (myDataArr[2] as NSString).doubleValue
                    //lastSessionCompliance.append(compDouble)
                } else {
                    print("[DEBUG] Invalid Data/Duplicate session number: " , session)
                }
                print("STATS")
                print(self.stats)
                print("STATS COUNT")
                print(self.stats.count)
            }
            // Clear out the resultString and sessionsAdded array once we have the data to prevent duplication
            resultString.removeAll()
            sessionsAdded.removeAll()
            self.syncSessionsToCoreData()
        }
        /*
        catch let error as NSError {
            // Sync Error Alert
            self.syncErrorAlert()
        }
        */
    }
    
    // Get number of sessions in core data
    private func getNumSessionsInCD() -> Int {
        var num_sessions_in_CD = 0
        do {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request: NSFetchRequest<Session> = Session.fetchRequest()
            num_sessions_in_CD = try context.count(for: request)
        } catch {
            // SyncViewController.syncErrorAlert()
            print("Could not get count of sessions from CD")
        }
        return num_sessions_in_CD
    }
    
    // Function to add data from stats (parsed data received from device) array to core data
    // Add sessions to core data and database
    private func syncSessionsToCoreData() {
        /* First, get max session number for this user from db
           Use this to determine new session numbers */
        // Create urlstr string with current userID
        let urlstr : String = "https://www.uvm.edu/~rtracker/Restful/sync.php?pmkPatientID=" + Util.returnCurrentUsersID()
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
            }
            /* Add sessions to core data and database */
            DispatchQueue.main.async {
                self.addData()
                // If the average compliance is higher than 55/60 minutes, give positive feedback
                //if ( Util.average(array: self.lastSessionCompliance) >= 0.9167 ){
                //    self.positiveFeedbackAlert()
                //}
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
                    // Sync Error Alert
                    //self.syncErrorAlert()
                    print("Could not find stats. \(error)")
                }
            }
        })
        task.resume()
    }
    private func addData() {
        var current_session_id = maxUserSessionNum
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textTransfer.isEditable = false
        textTransfer.text = nil
        
        //manager = CBCentralManager (delegate: self, queue: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}
