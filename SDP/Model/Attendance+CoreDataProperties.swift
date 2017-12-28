//
//  Attendance+CoreDataProperties.swift
//  SDP
//
//  Created by Liu Leung Kwan on 28/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//
//

import Foundation
import CoreData


extension Attendance {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attendance> {
        return NSFetchRequest<Attendance>(entityName: "Attendance")
    }

    @NSManaged public var attendanceDatetime: NSDate?
    @NSManaged public var id: String?
    @NSManaged public var status: String?
    @NSManaged public var uploadedFlag: Bool
    @NSManaged public var lesson: Lesson?

}
