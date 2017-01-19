//
//  Photo+CoreDataProperties.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var name: String?
    @NSManaged public var urlString: String?
    @NSManaged public var imageData: NSData?
    @NSManaged public var location: Location?

}
