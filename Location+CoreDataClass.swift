//
//  Location+CoreDataClass.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import Foundation
import CoreData
import MapKit


public class Location: NSManagedObject,MKAnnotation {

    convenience init(latitude: Double,longitude: Double,context: NSManagedObjectContext){
        if let en = NSEntityDescription.entity(forEntityName: "Location", in: context){
            self.init(entity:en, insertInto: context)
            self.latitude = latitude
            self.longitude = longitude
        }
        else{
            fatalError("Unable to find Entity name")
        }
    }
    
    public var coordinate: CLLocationCoordinate2D{
        return CLLocationCoordinate2DMake(self.latitude, self.longitude)
    }
}
