//
//  Constants.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import Foundation

extension Flickr{
    
    struct Constants {
        
        struct Flickr {
            static let ApiScheme = "https"
            static let ApiHost = "api.flickr.com"
            static let ApiPath = "/services/rest"
            
            static let searchBoxHalfWidth = 1.0
            static let searchBoxHalfHeight = 1.0
            static let searchLatRange = (-90.0,90.0)
            static let searchLonRange = (-180.0,180.0)
        }
        
        struct FlickrParameterKeys {
            static let Method = "method"
            static let ApiKey = "api_key"
            static let Extras = "extras"
            static let Format = "format"
            static let NoJSONCallBack = "nojsoncallback"
            static let SafeSearch = "safe_search"
            static let Text = "text"
            static let BoundingBox = "bbox"
            static let Page = "page"
        }
        
        struct FlickrParameterValues {
            static let SearchMethod = "flickr.photos.search"
            static let ApiKeyValue = "1dd99c5850c94276f9153472658831f5"
            static let ResponseFormat = "json"
            static let DisableJSONCallback = "1"
            static let galleryPhotosMethod = "flickr.galleries.getPhotos"
            static let MediumURL = "url_m"
            static let UseSafeSearch = "1"
        }
        
        struct FlickrResponseKeys {
            static let Status = "stat"
            static let Photos = "photos"
            static let Photo = "photo"
            static let Title = "title"
            static let MediumURL = "url_m"
            static let Pages = "pages"
            static let Total = "total"
            static let Perpage = "perpage"
        }
        
        struct FlickrResponseValues {
            static let OKStatus = "ok"
        }
    }
}
