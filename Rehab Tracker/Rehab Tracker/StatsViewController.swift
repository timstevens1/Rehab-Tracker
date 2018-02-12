//
//  StatsViewController.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 12/8/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//
// Need to give website props for the tab bar icon
// <a href="https://icons8.com/web-app/7318/Flex-Biceps">Flex biceps icon credits</a>
//

import UIKit
import Charts
import Foundation
import CoreData
import CoreBluetooth

// This pulls all the stats from Core Data
class StatsViewController: UIViewController {

    @IBOutlet weak var lineChartView: LineChartView!
    
    // Variables to hold data arrays
    private var sessions: [Double] = []
    private var dates: [String] = []
    private var intensity: [Double] = []
    private var dataPoints: [(Double,Double)] = []
    //private var dataPoints: [(Double,String,Double)] = []
    
    // Variable to hold the 
    private var limit = Util.returnTargetIntensity()
    
    // Variables to hold individual session stats
    private var fldSessNum = ""
    private var fldIntensity1 = ""
    private var fldIntensity2 = ""
    
    // Set chart function to create a chart from session data
    private func setLineChart(dataPoints: [Double], values: [Double]) {
        lineChartView.noDataText = "Loading..."
        var dataEntries: [ChartDataEntry] = []
        
        for i in 0..<dataPoints.count {
            let dataEntry = ChartDataEntry(x: dataPoints[i], y: values[i])
            dataEntries.append(dataEntry)
        }
        
        let chartDataSet = LineChartDataSet(values: dataEntries, label: "Average Session Intensity")
        let chartData = LineChartData(dataSet: chartDataSet)
        lineChartView.data = chartData
        
        // Aesthetic options for the chart
        lineChartView.chartDescription?.text = ""
        lineChartView.xAxis.labelPosition = .bottom
        DispatchQueue.main.async {
            self.lineChartView.backgroundColor = UIColor(red: 189/255, green: 195/255, blue: 199/255, alpha: 1)
        }
        lineChartView.animate(xAxisDuration: 2.0, yAxisDuration: 2.0)
        lineChartView.rightAxis.enabled = false
        lineChartView.xAxis.granularity = 1
        /*print("DATES")
        print(self.dates)
        lineChartView.xAxis.setLabelCount(self.dates.count, force: true)
        lineChartView.xAxis.valueFormatter = IndexAxisValueFormatter(values:self.dates)*/
        
        // Sets the target intensity
        let targetIntensity = ChartLimitLine(limit: limit, label: "Target Intensity")
        targetIntensity.labelPosition = .leftTop
        lineChartView.leftAxis.addLimitLine(targetIntensity)
    }
 
    // Function to get current user's session stats from db via ReST
    private func getStats() {
        // Create urlstr string with current userID
        let urlstr : String = Util.getHOST() + "Restful/getUserSessionsStats.php?pmkPatientID=" + Util.returnCurrentUsersID()
        // Make url string into actual url
        guard let url = URL(string: urlstr)
            else {
                print("Error: cannot create stats URL")
                return
        }
        // Create urlRequest using our url
        let urlRequest = URLRequest(url: url)
        
        let task = URLSession.shared.dataTask(with: urlRequest, completionHandler: {
            (data, response, error) in
            // If user sessions exist, save them
            if (error == nil) {
                let jo : NSDictionary
                do {
                    jo =
                        try JSONSerialization.jsonObject(with: data!, options: []) as! NSDictionary
                    print("JSON OBJECT RETURNED FROM REST")
                    print(jo)
                }
                catch {
                    return
                }
                let userSessions = jo.value(forKey: "userSessions") as! NSArray
                
                print("USER SESSIONS ARRAY")
                print(userSessions)
                
                for userSession in userSessions {
                    let userSessionDict = userSession as! NSDictionary
                    print("Session")
                    print(userSessionDict)
                    for session_data in userSessionDict {
                        print("data piece")
                        print(session_data)
                    }
                    //let sessionTime = userSessionDict["fldStartTime"] as! String
                    let sessionID = userSessionDict["fldSessNum"] as! String
                    print("SESSION ID")
                    print(sessionID)
                    let userID = Util.getCurrentUserID()
                    if (sessionID.count > userID.count) {
                        print("SESSION NUM STRING")
                        print(sessionID.suffix(sessionID.count - userID.count - 1))
                        }
                    if (sessionID.range(of:"_") != nil) {
                        let sessionNum = Double(sessionID.suffix(sessionID.count - userID.count - 1))
                        let sessionIntensity1 = Double(userSessionDict["fldIntensity1"] as! String)
                        let sessionIntensity2 = Double(userSessionDict["fldIntensity2"] as! String)
                        print("SESSION NUM")
                        print(sessionNum)
                        print("SESSION INTENSITY 1")
                        print(sessionIntensity1)
                        print ("SESSION INTENSITY 2")
                        print(sessionIntensity2)
                        if (sessionNum != nil && sessionIntensity1 != nil && sessionIntensity2 != nil) {
                            var sessionIntensityAvg = 0.0
                            if (sessionIntensity1! == 0) {
                                sessionIntensityAvg = sessionIntensity2!
                            } else if (sessionIntensity2! == 0){
                                sessionIntensityAvg = sessionIntensity1!
                            } else {
                                sessionIntensityAvg = Double((sessionIntensity1! + sessionIntensity2!)/2)
                            }
                            print("SESS INTENSITY AVG")
                            print(sessionIntensityAvg)
                            
                            // Append data for this session to dataPoints
                            self.dataPoints.append((sessionNum!,sessionIntensityAvg))
                            //self.dataPoints.append((sessionNum!,sessionTime,sessionIntensityAvg))
                            print("DATA BEFORE SORT")
                            print(self.dataPoints)
                        }
                    }
                }
                // Sort data points by session number (ascending)
                self.dataPoints.sort {$0.0 < $1.0}
                print("DATA AFTER SORT")
                print(self.dataPoints)
                // Append sorted data to the respective global arrays
                for dataPoint in self.dataPoints {
                    self.sessions.append(dataPoint.0)
                    //let sessionTimeNoYear = dataPoint.1.substring(from: String.Index(5))
                    //let sessionDate = sessionTimeNoYear.substring(to: String.Index(5))
                    //self.dates.append(sessionDate)
                    self.intensity.append(dataPoint.1)
                }
                print("SESSIONS")
                print(self.sessions)
                print("INTENSITIES")
                print(self.intensity)
                // Send data to charts
                self.setLineChart(dataPoints: self.sessions, values: self.intensity)
            }
            else {
                print(error)
            }
        })
        task.resume()
    }
    
    // TO DO - use core data if no internet connection!!!
    // Function to retrieve stats from core data
    /*private func getStats() {
        // Set up the request for Sessions
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request: NSFetchRequest< Session >=Session.fetchRequest()
        request.returnsObjectsAsFaults = false
        
        do {
            // Make the fetch request
            let coreSessions = try context.fetch( request  )
            
            // Loop through the resulting sessions and get data
            for val in coreSessions {
                // Get all the data we want to display from Core Data
                fldSessNum          = val.sessionID!
                fldIntensity1       = val.avg_ch1_intensity!
                fldIntensity2       = val.avg_ch2_intensity!
                
                // Cast gather data into doubles for the Charts package
                let fldSessNumDouble: Double        = Double( fldSessNum )!
                let intesityDouble1: Double         = Double( fldIntensity1 )!
                let intesityDouble2: Double         = Double( fldIntensity2 )!
                
                // Calculate true intensity from both paddles
                let realIntensity = intesityDouble1 + intesityDouble2
                
                // Append gathered data to the respective global arrays
                sessions.append( fldSessNumDouble )
                intensity.append( realIntensity )
            }
        }
        catch {
            print("Could not find stats. \(error)")
        }
    }*/

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Get data for graphs
        getStats()
        
        // perform a query to the database to get the target intensity
        Util.updateTargetIntensity()
        
        // Set the global variable limit to the target intensity in core data
        // Only reflects on graph if target intensity in in the data range
        limit = Util.returnTargetIntensity()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
