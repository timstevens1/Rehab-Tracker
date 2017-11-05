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

// (2) Delegates
// Eventually you are going to want to get callbacks from some functionality. There are two delegates to implement: CBCentralManagerDelegate, and CBPeripheralDelegate.
class PullViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    //(3) Declare Manager and Peripheral
    // The CBCentralManager install will be what you use to find, connect, and manage BLE devices. Once you are connected, and are working with a specific service, the peripheral will help you iterate characteristics and interacting with them.
    private var manager:CBCentralManager!
    private var peripheral:CBPeripheral!

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
            let resultString = resultNSString as String
            
            print(resultString)
            
            
            print("[DEBUG] Changing the text: ", NSString(format: "%llu", resultString) as String)
            
            
            //characteristic.value!.getBytes(&count, length: sizeof(UInt32))
            
            //lblTransfer.text = NSString(format: "%llu", resultString) as String
            lblTransfer.text = resultString
            textTransfer.text = resultString
        }
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
