//
//  User+CoreDataProperties.swift
//  Rehab Tracker
//
//  Created by Sean Kates on 12/5/16.
//  Copyright © 2017 University of Vermont. All rights reserved.
//

import Foundation
import CoreData

/// Create attributes and relationships for the entity `User`
extension User {
    /// Return a new fetch request initialized with the entity represented by this subclass
    @nonobjc public class func fetchRequest() -> NSFetchRequest<User> {
        return NSFetchRequest<User>(entityName: "User");
    }
    
    /// User's ID
    @NSManaged public var userID: String?
    /// User's target intensity that is provided by user's care provider
    @NSManaged public var targetIntensity: String?
    ///
    @NSManaged public var hasSession: NSSet?

}

// MARK: Generated accessors for hasSession
extension User {

    @objc(addHasSessionObject:)
    @NSManaged public func addToHasSession(_ value: Session)

    @objc(removeHasSessionObject:)
    @NSManaged public func removeFromHasSession(_ value: Session)

    @objc(addHasSession:)
    @NSManaged public func addToHasSession(_ values: NSSet)

    @objc(removeHasSession:)
    @NSManaged public func removeFromHasSession(_ values: NSSet)

}
