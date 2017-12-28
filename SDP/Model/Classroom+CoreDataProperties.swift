//
//  Classroom+CoreDataProperties.swift
//  SDP
//
//  Created by Liu Leung Kwan on 28/12/2017.
//  Copyright © 2017年 Liu Leung Kwan. All rights reserved.
//
//

import Foundation
import CoreData


extension Classroom {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Classroom> {
        return NSFetchRequest<Classroom>(entityName: "Classroom")
    }

    @NSManaged public var beaconId: String?
    @NSManaged public var id: String?
    @NSManaged public var location: String?
    @NSManaged public var name: String?
    @NSManaged public var uuid: String?
    @NSManaged public var lesson: Lesson?

}
