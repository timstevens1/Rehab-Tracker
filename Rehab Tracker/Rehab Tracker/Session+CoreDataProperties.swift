//
//  Session+CoreDataProperties.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 12/5/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import Foundation
import CoreData

/// Create attributes and relationships for the entity `session`
extension Session {

    /// Return a new fetch request initialized with the entity represented by this subclass
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Session> {
        return NSFetchRequest<Session>(entityName: "Session");
    }
    /// Average intensity of channel 1
    @NSManaged public var avg_ch1_intensity: String?
    /// Average intensity of channel 2
    @NSManaged public var avg_ch2_intensity: String?
    /// Finish time of the session
    @NSManaged public var end_time: Int32
    /// Notes that are typed by the user
    @NSManaged public var notes: String?
    /// Boolean value showing if this session has been pushed to database
    @NSManaged public var pushed_to_db: Bool
    /// Compliance percentage of this session
    @NSManaged public var session_compliance: String
    /// ID of this session
    @NSManaged public var sessionID: String?
    /// Start time of this session
    @NSManaged public var start_time: Int32
    ///
    @NSManaged public var hasUser: User?

}
