//
//  Lesson+CoreDataProperties.swift
//  SDP
//
//  Created by Liu Leung Kwan on 28/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//
//

import Foundation
import CoreData


extension Lesson {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Lesson> {
        return NSFetchRequest<Lesson>(entityName: "Lesson")
    }

    @NSManaged public var code: String?
    @NSManaged public var endDatetime: NSDate?
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var startDatetime: NSDate?
    @NSManaged public var attendance: Attendance?
    @NSManaged public var teacher: NSSet?
    @NSManaged public var classroom: Classroom?

}

// MARK: Generated accessors for teacher
extension Lesson {

    @objc(addTeacherObject:)
    @NSManaged public func addToTeacher(_ value: Teacher)

    @objc(removeTeacherObject:)
    @NSManaged public func removeFromTeacher(_ value: Teacher)

    @objc(addTeacher:)
    @NSManaged public func addToTeacher(_ values: NSSet)

    @objc(removeTeacher:)
    @NSManaged public func removeFromTeacher(_ values: NSSet)

}
