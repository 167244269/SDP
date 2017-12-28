//
//  Teacher+CoreDataProperties.swift
//  SDP
//
//  Created by Liu Leung Kwan on 28/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//
//

import Foundation
import CoreData


extension Teacher {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Teacher> {
        return NSFetchRequest<Teacher>(entityName: "Teacher")
    }

    @NSManaged public var email: String?
    @NSManaged public var id: String?
    @NSManaged public var name: String?
    @NSManaged public var office: String?
    @NSManaged public var phoneNo: String?
    @NSManaged public var lessons: NSSet?

}

// MARK: Generated accessors for lessons
extension Teacher {

    @objc(addLessonsObject:)
    @NSManaged public func addToLessons(_ value: Lesson)

    @objc(removeLessonsObject:)
    @NSManaged public func removeFromLessons(_ value: Lesson)

    @objc(addLessons:)
    @NSManaged public func addToLessons(_ values: NSSet)

    @objc(removeLessons:)
    @NSManaged public func removeFromLessons(_ values: NSSet)

}
