//
//  Photo+CoreDataClass.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import Foundation
import CoreData
import UIKit

public class Photo: NSManagedObject {

    convenience init(imageName: String,imageURLString: String,context: NSManagedObjectContext){
        if let en = NSEntityDescription.entity(forEntityName: "Photo", in: context){
            self.init(entity:en, insertInto: context)
            self.name = imageName
            self.urlString = imageURLString

        }
        else{
            fatalError("Unable to find Entity name")
        }
    }
    
//    convenience init(imageData: NSData,context: NSManagedObjectContext){
//        if let en = NSEntityDescription.entity(forEntityName: "Photo", in: context){
//            self.init(entity:en, insertInto:context)
//            self.imageData = imageData
//        }
//        else{
//            fatalError("Unable to find entity name")
//        }
//    }
    
//    public var image = UIImage(dat)
}
