//
//  Session+CoreDataProperties.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 12/5/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import Foundation
import CoreData

// Create attributes and relationships for the entity `session`
/// :nodoc:
extension Session {

    // Return a new fetch request initialized with the entity represented by this subclass
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session");
    }
    
    @NSManaged public var avg_ch1_intensity: String?
    
    @NSManaged public var avg_ch2_intensity: String?
    
    @NSManaged public var end_time: Int32
    
    @NSManaged public var notes: String?
    
    @NSManaged public var pushed_to_db: Bool
    
    @NSManaged public var session_compliance: String
    
    @NSManaged public var sessionID: String?
    
    @NSManaged public var start_time: Int32
    
    @NSManaged public var hasUser: User?

}
