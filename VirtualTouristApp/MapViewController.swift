//
//  MapViewController.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class MapViewController: UIViewController,MKMapViewDelegate,NSFetchedResultsControllerDelegate  {

    @IBOutlet weak var mainMapView: MKMapView!
    var savedPin: Location!
    var savedPins = [Location]()
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    let alert = AlertViewController()
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
            fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                                  NSSortDescriptor(key: "longitude", ascending: true)]
            
            fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            executeSearch()
            self.configure()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.savedRegion()
        self.navigationController?.navigationBar.isHidden = true
        mainMapView.delegate = self
        let longPressGesture = UILongPressGestureRecognizer(target: self,action:#selector(longPressRecognizer(gestureRecognizer:)))
        longPressGesture.minimumPressDuration = 0.5
        mainMapView.addGestureRecognizer(longPressGesture)
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Location")
        fr.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true),
                              NSSortDescriptor(key: "longitude", ascending: true)]
        
        fetchedResultsController?.delegate = self
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    
    func savedRegion(){
        
        let hasAlreadyLaunched = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if hasAlreadyLaunched{
            let isVeryfirstTime = UserDefaults.standard.value(forKey: "veryFirstTime") as! Bool
            if isVeryfirstTime{
                let lat = UserDefaults.standard.value(forKey: "latitude") as! CLLocationDegrees
                let lon = UserDefaults.standard.value(forKey: "longitude") as! CLLocationDegrees
                let centre = CLLocationCoordinate2D(latitude: lat,longitude: lon)
                
                let latDelta = UserDefaults.standard.value(forKey: "latitudeDelta") as! CLLocationDegrees
                let lonDelta = UserDefaults.standard.value(forKey: "longitudeDelta") as! CLLocationDegrees
                let span = MKCoordinateSpan(latitudeDelta: latDelta,longitudeDelta: lonDelta)
                
                let savedArea = MKCoordinateRegion(center: centre,span: span)
                mainMapView.setRegion(savedArea, animated: true)
            }
            
        }
    }
    
    func longPressRecognizer(gestureRecognizer: UILongPressGestureRecognizer){
        
        let touchPoint:CGPoint = gestureRecognizer.location(in: mainMapView)
        let annotationCoordinate : CLLocationCoordinate2D = mainMapView.convert(touchPoint, toCoordinateFrom: mainMapView)
        
        DispatchQueue.main.async {
            
            switch gestureRecognizer.state {
            case .began:
                let annotation = Location(latitude: annotationCoordinate.latitude, longitude: annotationCoordinate.longitude,context: self.stack.context)
                Flickr.shareInstance().getPhotosWithPages(location: annotation, withPageNumber: 1){(success,error) in
                    
                    if !success{
                        DispatchQueue.main.async {
                            self.alert.displayAlertView(viewController:self,alertTitle: "Error while downloading photos",alertMessage: (error?.localizedDescription)!)
                        }
                    }
                    else{
                        DispatchQueue.main.async {
                            self.mainMapView.addAnnotation(annotation)
                            self.savedPin = annotation
                            self.savedPins.append(self.savedPin)
                            self.stack.save()
                        }
                    }
                }
            default:
                return
            }
        }
    }
    
    func configure(){
        
        DispatchQueue.main.async {
            self.mainMapView.removeAnnotations(self.mainMapView.annotations)
            let fetchedResultAnnotations = self.fetchedResultsController?.fetchedObjects as! [Location]
            self.mainMapView.addAnnotations(fetchedResultAnnotations)
            self.savedPins = fetchedResultAnnotations
        }
    }
    
    func executeSearch(){
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }
            catch let e as NSError{
                print("Error while performing a search: \n \(e) \n \(fetchedResultsController)")
                DispatchQueue.main.async {
                    self.alert.displayAlertView(viewController:self,alertTitle: "Error in executing search",alertMessage: "Error while performing a search: \n \(e) \n \(self.fetchedResultsController)")
                }
            }
        }
    }
    
    //MapViewDelgate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.pinTintColor = .red
            pinView?.animatesDrop = true
            pinView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        
        let locationPoint = view.annotation as! Location
        let location = CLLocation(latitude: locationPoint.latitude,longitude: locationPoint.longitude)
        var locationName = String()
        
        let geoCoder = CLGeocoder()
        geoCoder.reverseGeocodeLocation(location) {(placemarks,error) in
            if error == nil{
                DispatchQueue.main.async {
                    if let placeMark:CLPlacemark = placemarks?.first{
                        print(placeMark.addressDictionary!)
                        print(placeMark)
                        if let placeDetails = placeMark.addressDictionary{
                            let placeName = placeDetails["SubLocality"]
                            locationName = placeName  as! String
                            print(locationName)
                        }
                    }
                    
                    let photoAlbumVC = self.storyboard?.instantiateViewController(withIdentifier: "PhotosCollectionVC") as! PhotosCollectionViewController
                    for pin in self.savedPins{
                        if pin == locationPoint{
                            photoAlbumVC.location = pin
                            print(photoAlbumVC.location)
                        }
                        else{
                            photoAlbumVC.location = locationPoint
                            print(photoAlbumVC.location)
                        }
                    }
//                    let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
//                    
//                    fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),NSSortDescriptor(key: "urlString", ascending: true),NSSortDescriptor(key: "imageData", ascending: true)]
//                    
//                    let pred = NSPredicate(format: "location = %@", argumentArray: [locationPoint])
//                    fr.predicate = pred
//                    let fetchController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext:self.fetchedResultsController!.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
//                    photoAlbumVC.fetchedResultsController = fetchController
                    photoAlbumVC.placeName = locationName
                    photoAlbumVC.count = 1
                    self.navigationController?.pushViewController(photoAlbumVC, animated: true)
                }
            }
            else{
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        UserDefaults.standard.set(mainMapView.region.center.latitude, forKey: "latitude")
        UserDefaults.standard.set(mainMapView.region.center.longitude, forKey: "longitude")
        UserDefaults.standard.set(mainMapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        UserDefaults.standard.set(mainMapView.region.span.longitudeDelta, forKey: "longitudeDelta")
        UserDefaults.standard.set(true, forKey: "veryFirstTime")
        
    }
    
    //FetchedResultControllerDelegate
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            mainMapView.addAnnotation(anObject as! Location)
        case .delete:
            mainMapView.removeAnnotation(anObject as! Location)
        case .update:
            mainMapView.addAnnotation(anObject as! Location)
            mainMapView.removeAnnotation(anObject as! Location)
        case .move:
            break
        }
    }

}
