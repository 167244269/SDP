//
//  StudentInfo+CoreDataProperties.swift
//  SDP
//
//  Created by Liu Leung Kwan on 28/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//
//

import Foundation
import CoreData


extension StudentInfo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<StudentInfo> {
        return NSFetchRequest<StudentInfo>(entityName: "StudentInfo")
    }

    @NSManaged public var academicYear: String?
    @NSManaged public var authToken: String?
    @NSManaged public var autoFlag: Bool
    @NSManaged public var courseCode: String?
    @NSManaged public var courseId: String?
    @NSManaged public var courseName: String?
    @NSManaged public var department: String?
    @NSManaged public var id: String?
    @NSManaged public var lastLoginDatetime: NSDate?
    @NSManaged public var lastDataSyncDatetime: NSDate?
    @NSManaged public var name: String?
    @NSManaged public var sha256: String?

}
