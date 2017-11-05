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

// The purpose of this file is for Syncing data to the database, and the BLE Code

import UIKit
import CoreData
import Foundation
import CoreBluetooth

// DEBUG mode flag
let DEBUG = true

protocol BLEDelegate1 {
    func bleDidUpdateState()
    func bleDidConnectToPeripheral()
    func bleDidDisconenctFromPeripheral()
    func bleDidReceiveData(data: NSData?)
}

class SyncViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate  {
    
    // global variable comments to store session comments
    private var comments = "No Comments"
    
    // Array to hold all the session compliances to check for positive feedback
    private var lastSessionCompliance = [Double]()
    
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
    
    // Show an alert if there was an error with syncing the data
    private func syncErrorAlert() {
        // create the alert
        let alert = UIAlertController(title: "Sync Error", message: "There was an error syncing your data, please try again!", preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
    }
    
    // Show an alert with positive feedback after the sync
    private func positiveFeedbackAlert() {
        // create the alert
        let alert = UIAlertController(title: "Keep it up!", message: Util.getPositiveFeedback(), preferredStyle: UIAlertControllerStyle.alert)
        
        // add an action (button)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
        
        // show the alert
        self.present(alert, animated: true, completion: nil)
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
                                        let textField = alert.textFields!.first
                                        
                                        // Saves input to global comments var
                                        self.comments = textField!.text!
                                        
                                        do {
                                            // Disconnects from the BLE Device
                                            if(self.activePeripheral != nil){
                                                // Write true to the Blend so it knows we are disconnecting
                                                // var flag = true;
                                                // let data = NSData(bytes: &flag, length: MemoryLayout<Bool>.size)
                                                // self.write(data: data)
                                                    
                                                // Disconnect
                                                _ = self.disconnectFromPeripheral(peripheral: self.activePeripheral!)
                                            }else{
                                                print("[DEBUG] There is no peripheral to be disconnected")
                                                
                                                self.dataFromPeripheral = ["SCAR8,60,62,0.91,1509821900,1509821924","RED8,49,51,0.12,1509821800,1509821899"]
                                               // TEMP - DEBUGGING MEASURE TO CLEAR PREV USER SESSIONS
                                                //Util.overwriteSessions()
                                                
                                                // Get new sessions from core data and push to db
                                                try self.getAndSynchNewSessions()
                                                self.pushToDatabase()
                                            }
                                            
                                            // If the average compliance is higher than 55/60 minutes, give positive feedback
                                            if ( Util.average(array: self.lastSessionCompliance) >= 0.9167 ){
                                                self.positiveFeedbackAlert()
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
                                                    // Assign values for post variables
                                                    let num = val.sessionID!
                                                    print("FLD_SESS_NUM") //DEBUG STEP
                                                    print(num)
                                                }
                                                
                                            }catch {
                                                // Sync Error Alert
                                                self.syncErrorAlert()
                                                
                                                print("Could not find stats. \(error)")
                                            }
                                        }
                                        catch {
                                            print("Could not find stats. \(error)")
                                            
                                            // Sync Error Alert
                                            self.syncErrorAlert()
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
        let datetime = Date(timeIntervalSince1970: Double(seconds_since_1970))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: datetime)
    }
    
    // Function to retrieve new session info from core data
    private func getAndSynchNewSessions() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest<Session> = Session.fetchRequest()
        request.predicate = NSPredicate(format: "pushed_to_db == false")
        request.returnsObjectsAsFaults = false
        
        do {
            sessions = try context.fetch(request)
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
            
        }catch {
            // Sync Error Alert
            self.syncErrorAlert()
            print("Could not find new sessions. \(error)")
        }
    }
    
    private func pushToDatabase() {
        let urlstr : String = "https://www.uvm.edu/~rtracker/Restful/sync.php"
        
        //Make url string into actual url and catch errors
        guard let url = URL(string: urlstr)
            else {
            // Sync Error Alert
            self.syncErrorAlert()
            
            print("Error: cannot create URL")
            return
        }
        
        // Creates urlRequest using our url
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"

        do {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: sessionsJson, options: [])
        } catch let error {
            print(error.localizedDescription)
        }
        
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json", forHTTPHeaderField: "Accept")
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler:{
            (data, response, error) in
            if error != nil {
                // Sync Error Alert
                self.syncErrorAlert()
                
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
            request.predicate = NSPredicate(format: "sessionID == %@", session.1["fldSessNum"] as! CVarArg)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
        self.data = NSMutableData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //***************************//
    // MARK: Bluetooth (BLE) Code
    
    /*
     CoreBluetooth Process:
     1. When view loads, centralManager is declared and checks the centralManager.state,
        If and only if the state = .poweredOn can the centralManager do anything.
        To check for the state, centralManagerDidUpdateState is called and updates state.
     2. To scan for BLE, startScanning() is called as long as state = .poweredOn
     3. The centralManager then calls scanForPeripherals(services) which scans for BLE devices with specific services.
        These services are determined by the UUID string on the BLE device.
     4. If a device is found with that service, then didDiscoverPeripheral() is called.
     5. didDiscoverPeripheral() then attempts to connect to the peripheral that was discovered, if the connect is
        successful, didConnect() is called. If its unsuccessful, didFailToConnect() is called.\
     6. In the event of a successful connection (didConnect()) we then query the peripheral for the services,
        and for the characteristics of those services using the didDiscoverServices() and didDiscoverCharacteristics()
     7.
    */
 
    // Initialize the UUID's
    let RBL_SERVICE_UUID = "713D0000-503E-4C75-BA94-3148F18D941E"
    let RBL_CHAR_TX_UUID = "713D0002-503E-4C75-BA94-3148F18D941E"
    let RBL_CHAR_RX_UUID = "713D0003-503E-4C75-BA94-3148F18D941E"
    let RBL_BLE_FRAMEWORK_VER = 0x0200

    //let my_UUID = "023DD007-7C99-447F-BE6A-9B9F18287FFB"
    
    // Initialize the BLEDelgate as delegate
    var delegate: BLEDelegate1?
    
    // Initialize all needed variables (make private)
    private      var centralManager:   CBCentralManager!
    private      var activePeripheral: CBPeripheral?
    private      var characteristics = [String : CBCharacteristic]()
    private      var data:             NSMutableData?
    private(set) var peripherals     = [CBPeripheral]()
    private      var RSSICompletionHandler: ((NSNumber?, NSError?) -> ())?
    
    var dataFromPeripheral = [String]()
    
    // Private function to stop the scan after the scan has timed-out
    @objc private func scanTimeout() {
        self.centralManager.stopScan()
        if activePeripheral == nil {
            print("[DEBUG] No peripherals were found, stopping scan")
        }
    }
    
    // Function that gets called when the connect button is clicked on the screen
    // Starts scanning for periferals
    @IBAction func connectBLE(_ sender: Any) {
        _ = self.startScanning(timeout: 10)
    }
    
    // MARK: Public methods
    
    // Function to start scanning for BLE's, takes the timeout as a boolean, returns boolean
    func startScanning(timeout: Double) -> Bool {
        
        if self.centralManager.state != .poweredOn {
            print("[ERROR] Couldn´t start scanning")
            return false
        }
        
        print("**************************")
        print("[DEBUG] Scanning started")
        
        // CBCentralManagerScanOptionAllowDuplicatesKey
        
        // Creates a timer to check the time
        Timer.scheduledTimer(timeInterval: timeout, target: self, selector: #selector(self.scanTimeout), userInfo: nil, repeats: false)
        
        // Initialize the services and call the scanForPeripherals functions with the services
        let services:[CBUUID] = [CBUUID(string: RBL_SERVICE_UUID)]
        self.centralManager.scanForPeripherals(withServices: services, options: nil)
        
        // return true if the scanning happened
        return true
    }
    
    // Method to connect to peripheral that we have found
    func connectToPeripheral(peripheral: CBPeripheral) -> Bool {
        
        if self.centralManager.state != .poweredOn {
            
            print("[ERROR] Couldn´t connect to peripheral")
            return false
        }
        
        print("[DEBUG] Connecting to peripheral: \(peripheral.identifier.uuidString)")
        
        self.centralManager.connect(peripheral, options: [CBConnectPeripheralOptionNotifyOnDisconnectionKey : NSNumber(value: true)])
        
        return true
    }
    
    // Method to disconnect from the peripheral
    func disconnectFromPeripheral(peripheral: CBPeripheral) -> Bool {
        if self.centralManager.state != .poweredOn {
            
            print("[ERROR] Couldn´t disconnect from peripheral")
            return false
        }
        
        self.centralManager.cancelPeripheralConnection(peripheral)
        
        return true
    }
    
    // MARK: CBCentralManager delegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOn:
            print("[DEBUG] Central manager state: Powered on")
            break
            
        case .unknown:
            print("[DEBUG] Central manager state: Unknown")
            break
            
        case .resetting:
            print("[DEBUG] Central manager state: Resseting")
            break
            
        case .unsupported:
            print("[DEBUG] Central manager state: Unsopported")
            break
            
        case .unauthorized:
            print("[DEBUG] Central manager state: Unauthorized")
            break
            
        case .poweredOff:
            print("[DEBUG] Central manager state: Powered off")
            break
        }
        
        self.delegate?.bleDidUpdateState()
    }
    
    // Function called if peripherals are discovered during scanForPeripherals() function call with specific services
    func centralManager(_ central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject],RSSI: NSNumber) {
        print("[DEBUG] Found peripheral:", peripheral.identifier.uuidString, "With RSSI:", RSSI)
        
        if (!peripherals.contains(peripheral)){
            peripherals.append(peripheral)
        }
        
        // Try to connect to the peripheral
        _ = self.connectToPeripheral(peripheral: peripheral)
    }
    
    // If the connection was unsuccessful, print an error saying we failed to connect
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("[ERROR] Could not connect to peripheral \(peripheral.identifier.uuidString) error: \(String(describing: error))")
    }
    
    // If the connection was successful, set the activePeripheral to peripheral and discoverServices()
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        print("[DEBUG] Connected to peripheral \(peripheral.identifier.uuidString)")
        
        self.activePeripheral = peripheral
        
        self.activePeripheral?.delegate = self
        self.activePeripheral?.discoverServices([CBUUID(string: RBL_SERVICE_UUID)])
        
        self.delegate?.bleDidConnectToPeripheral()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        var text = "[DEBUG] Disconnected from peripheral: \(peripheral.identifier.uuidString)"
        
        if error != nil {
            text += ". Error: \(String(describing: error))"
        }
        
        print(text)
        
        self.activePeripheral?.delegate = nil
        self.activePeripheral = nil
        self.characteristics.removeAll(keepingCapacity: false)
        
        self.delegate?.bleDidDisconenctFromPeripheral()
        
        // Once disconnected, write all the data you got to the CSV
        //writeToCSV()
        //Util.readDataFromFile(file: "data")
    }
    
    // MARK: CBPeripheral delegate
    
    // didDiscoverServices() is called once a connection is formed with the peripheral
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        
        if error != nil {
            print("[ERROR] Error discovering services. \(String(describing: error))")
            return
        }
        
        print("[DEBUG] Found services for peripheral: \(peripheral.identifier.uuidString)")
        
        
        for service in peripheral.services! {
            let theCharacteristics = [CBUUID(string: RBL_CHAR_RX_UUID), CBUUID(string: RBL_CHAR_TX_UUID)]
            
            peripheral.discoverCharacteristics(theCharacteristics, for: service)
        }
    }
    
    // didDiscoverCharacteristics is called if services are found on the peripheral, we want those characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        if error != nil {
            print("[ERROR] Error discovering characteristics. \(String(describing: error))")
            return
        }
        
        print("[DEBUG] Found characteristics for peripheral: \(peripheral.identifier.uuidString)")
        
        for characteristic in service.characteristics! {
            self.characteristics[characteristic.uuid.uuidString] = characteristic
        }
        
        enableNotifications(enable: true)
        read()
    }
    
    // Use the data we receive from the peripheral
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        
 
        
        if error != nil {
            
            print("[ERROR] Error updating value. \(String(describing: error))")
            return
        }

        if characteristic.uuid.uuidString == RBL_CHAR_TX_UUID {
            self.delegate?.bleDidReceiveData(data: characteristic.value as NSData?)
            
        }else{
            print("[DEBUG] characteristic UUID is wrong")
        }
        
        // Convert NSData to NSString to String
        let resultNSString = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue)!
        let resultString = resultNSString as String
        print("$$$$$$$$$$$$$$$$$$$$$")
        print(resultString)
        
        // Append the data string to the data array
        dataFromPeripheral.append(resultString)
        
    }
    
    // didReadRSSI function
    func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        self.RSSICompletionHandler?(RSSI, error as NSError?)
        self.RSSICompletionHandler = nil
    }
    
    // Reads value of the characteristic from the peripheral
    func read() {
        
        print("[DEBUG] Reading characteristic from the peripheral")
        
        guard let char = self.characteristics[RBL_CHAR_RX_UUID] else { return }
        
        self.activePeripheral?.readValue(for: char)
    }
    
    // Writes data
    func write(data: NSData) {
        print("Write function activated!")
        guard let char = self.characteristics[RBL_CHAR_RX_UUID] else { return }
        
        self.activePeripheral?.writeValue(data as Data, for: char, type: .withoutResponse)
    }
    
    func enableNotifications(enable: Bool) {
        
        guard let char = self.characteristics[RBL_CHAR_TX_UUID] else { return }
        
        self.activePeripheral?.setNotifyValue(enable, for: char)
    }
    
    // Reads the RSSI from the peripheral and updates the field
    func readRSSI(completion: @escaping (_ RSSI: NSNumber?, _ error: NSError?) -> ()) {
        
        self.RSSICompletionHandler = completion
        self.activePeripheral?.readRSSI()
    }
    
    // Write what is in the dataFromPeripheral array to a CSV
    /*func writeToCSV() {
        var singleSessionArray = [String]()
        
        // First break up the data array by newlines to seperate out each session
        print("===========", dataFromPeripheral);
        for myData in dataFromPeripheral{
            singleSessionArray = myData.components(separatedBy: "\n")
        }
        
        // Initialize variables to hold what we will be writing
        var csvText = ""
        var newLine = ""
        
        // Create an array to track which sessions weve synced
        var sessionsAdded = [Character]()
        
        for session in singleSessionArray{
            let myDataArr = session.components(separatedBy: ",")
            
            // Get the first character of the data string which is the session Count to make sure no duplicated
            let index = session.index(session.startIndex, offsetBy: 0)
            
            // Check if the array contains 4 data points and that the sessionCount isnt duplicating
            if (myDataArr.count == 4 && !sessionsAdded.contains(session[index])){
                // Add validated data to what will be written to csv
                newLine = "\(session)\n"
                csvText.append(newLine)
                sessionsAdded.append(session[index]);
            }else{
                print("[DEBUG] Invalid Data/Duplicate session number: " , session)
            }
        }
        
        // Clear out the dataFromPeripheral array once we have the data to prevent duplication
        dataFromPeripheral.removeAll()
        singleSessionArray.removeAll()
        sessionsAdded.removeAll()
        
        // Writing time!
        let fileName = "data"
        let docDirectory = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        if let fileURL = docDirectory?.appendingPathComponent(fileName).appendingPathExtension("csv") {
            
            // Write to a file on disk
            do {
                print("[DEBUG] Attempting to write to file!")
                
                // Print out the csvTest
                print("[DEBUG] What we are writing:\n", csvText)
                
                try csvText.write(to: fileURL, atomically: true, encoding: .utf8)
                
                // NEED TO CHANGE THIS - DEBUGGING MEASURE TO CLEAR PREV USER SESSIONS
                //Util.overwriteSessions()
                
            } catch {
                print("[ERROR] Failed writing to URL: \(fileURL), Error: " + error.localizedDescription)
            }
        }
    }*/
}
