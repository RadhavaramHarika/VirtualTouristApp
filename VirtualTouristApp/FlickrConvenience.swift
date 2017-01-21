//
//  FlickrConvenience.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import Foundation
import UIKit
import MapKit

extension Flickr{
    
    public func getPhotosWithPages(location: Location,withPageNumber:Int, getPhotosWithPagescompletionHandler: @escaping(_ success: Bool,_ error: NSError?) -> Void){
        
        let pageNum = withPageNumber
        var methodParams:[String:AnyObject] = [Constants.FlickrParameterKeys.Method: Constants.FlickrParameterValues.SearchMethod as AnyObject,
                                               Constants.FlickrParameterKeys.ApiKey: Constants.FlickrParameterValues.ApiKeyValue as AnyObject,
                                               Constants.FlickrParameterKeys.BoundingBox: self.bboxString(latitude: location.latitude, longitude: location.longitude) as AnyObject,
                                               Constants.FlickrParameterKeys.SafeSearch: Constants.FlickrParameterValues.UseSafeSearch as AnyObject,
                                               Constants.FlickrResponseKeys.Perpage: 20 as AnyObject,
                                               Constants.FlickrParameterKeys.Extras: Constants.FlickrParameterValues.MediumURL as AnyObject,
                                               Constants.FlickrParameterKeys.Format: Constants.FlickrParameterValues.ResponseFormat as AnyObject,
                                               Constants.FlickrParameterKeys.NoJSONCallBack: Constants.FlickrParameterValues.DisableJSONCallback as AnyObject]
        let task = taskToGetPhotosDictionary(methodParams as [String : AnyObject]){(results,error) in
            
            if error != nil {
                getPhotosWithPagescompletionHandler(false,error)
            }
            
            if let photoResults = results{
                
                guard let stat = photoResults[Constants.FlickrResponseKeys.Status] as? String, stat == Constants.FlickrResponseValues.OKStatus else{
                    print("Flickr Api returned an error, see the message in \(results)")
                    return
                }
                
                guard let photosDictionary = photoResults[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else{
                    print("Could not find the key \(Constants.FlickrResponseKeys.Photos)")
                    return
                }
                
                guard let totalPages = photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int else{
                    print("Could not find the key \(Constants.FlickrResponseKeys.Pages)")
                    return
                }
                
                guard let perPage = photosDictionary[Constants.FlickrResponseKeys.Perpage] as? Int else{
                    print("Could not find the key \(Constants.FlickrResponseKeys.Perpage)")
                    return
                }
                print(perPage)
//                let pageLimit = min(totalPages,40)
//                if pageNum <= pageLimit{
                    methodParams[Constants.FlickrParameterKeys.Page] = pageNum as AnyObject?
//                    methodParams[Constants.FlickrResponseKeys.Perpage] = 20 as AnyObject?
                    self.getPhotosWithPageNumber(methodParams,location:location,getPhotosWithPageNumberCompletionHandler: getPhotosWithPagescompletionHandler)
//                }
//                else{
//                    getPhotosWithPagescompletionHandler(false,NSError(domain:"getPhotoswithPages",code:1,userInfo:[NSLocalizedDescriptionKey:"Exceeded PageLimit"]))
//                }
                
            }
            else{
                getPhotosWithPagescompletionHandler(false,NSError(domain: "getPhotosWithPages",code: 1,userInfo:[NSLocalizedDescriptionKey:"Data found as nil"]))
            }
            
        }
    }
    
    func getPhotosWithPageNumber(_ methodParameters: [String:AnyObject],location: Location,getPhotosWithPageNumberCompletionHandler:@escaping(_ success:Bool,_ error: NSError?) -> Void){
        
        let parameters = methodParameters
        
        let task = taskToGetPhotosDictionary(parameters){(results,error) in
            
            if error != nil{
                getPhotosWithPageNumberCompletionHandler(false,error)
            }
            
            if let photoResults = results{
                guard let stat = photoResults[Constants.FlickrResponseKeys.Status] as? String,stat == Constants.FlickrResponseValues.OKStatus else{
                    print("Flickr Api returned an error, see the message in \(results)")
                    getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"Flickr Api returned an error, see the message in \(results)"]))
                    
                    return
                }
                
                guard let photosDictionary = photoResults[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else{
                    print("Could not find th key \(Constants.FlickrResponseKeys.Photos)")
                    getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"Could not find th key \(Constants.FlickrResponseKeys.Photos)"]))
                    return
                }
                
                guard let photosArray = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else{
                    print("Could not find the key \(Constants.FlickrResponseKeys.Photo)")
                    getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"Could not find the key \(Constants.FlickrResponseKeys.Photo)"]))
                    return
                }
                
                if photosArray.count == 0{
                    print("No photo is found,Search Again")
                    getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"No photo is found,Search Again"]))
                    
                    return
                }
                else{
                    print(photosArray.count)
                    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
                    
                    if photosArray.count > 20{
                    let photoArray = photosArray[0..<20]
                    print(photoArray.count)
                    var count = 1
                    for eachPhoto in photoArray{
                            let photoTitle = eachPhoto[Constants.FlickrResponseKeys.Title] as? String
                            
                            guard let mediumURL = eachPhoto[Constants.FlickrResponseKeys.MediumURL] as? String else{
                                print("Could not find the key \(Constants.FlickrResponseKeys.MediumURL)")
                                getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"Could not find the key \(Constants.FlickrResponseKeys.MediumURL)"]))
                                return
                            }
//                        DispatchQueue.main.async {
                        stack.context.perform {
                            
                            let photo = Photo(imageName: photoTitle!,imageURLString: mediumURL, context:stack.context)
                            print(count)
                            count += 1
                            photo.location = location
                            print(photo.location)
                            print(photo)
                            stack.save()
                        }
                    }
                    getPhotosWithPageNumberCompletionHandler(true,nil)
                    }

                }
            }
            else{
                
                getPhotosWithPageNumberCompletionHandler(false,NSError(domain: "getPhotosWithPageNumber",code: 1,userInfo:[NSLocalizedDescriptionKey:"Data found as nil!"]))
            }
        }
        
    }
    
    func downloadImageFromImageURL(imagePath: String, completionHandlerForImageDownload: @escaping(_ success:Bool,_ imageData: Data?,_ error: NSError?) -> Void){
        
        let imageURL = URL(string: imagePath)
        let request = URLRequest(url: imageURL!)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) {(data,response,error) in
            
            if error != nil{
                completionHandlerForImageDownload(false,nil,NSError(domain:"ImageDownLoad",code: 1,userInfo:[NSLocalizedDescriptionKey:"Could not dowloadImage"]))
            }
            else{
                completionHandlerForImageDownload(true,data,nil)
            }
        }
        task.resume()
    }
    
    private func bboxString(latitude: Double!,longitude:Double!) -> String {
        if let lat = latitude, let lon = longitude {
            let minimumLon = max(lon - Constants.Flickr.searchBoxHalfWidth, Constants.Flickr.searchLonRange.0)
            let minimumLat = max(lat - Constants.Flickr.searchBoxHalfHeight, Constants.Flickr.searchLatRange.0)
            let maximumLon = min(lon + Constants.Flickr.searchBoxHalfWidth, Constants.Flickr.searchLonRange.1)
            let maximumLat = min(lat + Constants.Flickr.searchBoxHalfHeight, Constants.Flickr.searchLatRange.1)
            return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
        } else {
            return "0,0,0,0"
        }
    }
    
}
