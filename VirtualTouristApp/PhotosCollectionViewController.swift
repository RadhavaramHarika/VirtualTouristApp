//
//  PhotosCollectionViewController.swift
//  VirtualTouristApp
//
//  Created by radhavaram harika on 1/18/17.
//  Copyright © 2017 Practise. All rights reserved.
//

import UIKit
import CoreData
import MapKit

class PhotosCollectionViewController: UIViewController,MKMapViewDelegate,NSFetchedResultsControllerDelegate,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,UINavigationControllerDelegate {


    @IBOutlet weak var bottomToolBar: UIToolbar!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoCollectionViewFlowLayout: UICollectionViewFlowLayout!
    var location:Location!
    var placeName:String!
    @IBOutlet weak var mapView: MKMapView!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    let alert = AlertViewController()
    
    var insertedPaths: [IndexPath]!
    var deletedPaths: [IndexPath]!
    var updatedPaths: [IndexPath]!
    var selectedIndices = [IndexPath]()
    
    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            fetchedResultsController?.delegate = self
            executeSearch()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        self.mapView.delegate = self
        photoCollectionView.reloadData()
        
        self.fetchedResultsController?.delegate = self
        self.navigationController?.navigationBar.isHidden = false
        self.view.bringSubview(toFront: bottomToolBar)
        
        self.setUpMapView()
        self.setUpFlowLayout()
    }
    
    func getImages(){
        Flickr.shareInstance().getImageData(selectedLocation: location){(success,error)in
        
            if success{
                print("Successfully downloaded imageData")
            }
            else{
                print("Could not download image data")
                print(error)
            }
        }
    }
    
    func getFetchResults(){
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: false),NSSortDescriptor(key: "urlString", ascending: true),NSSortDescriptor(key: "imageData", ascending: true)]
        print(self.location)
        let predicate = NSPredicate(format: "location: %@", argumentArray: [location])
        fr.predicate = predicate
        
        //         Create the FetchedResultsController
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func setUpMapView(){
        
        let annotation = self.location
        let place = self.placeName
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(place!) {(placeMarks, error) in
            
            if error != nil
            {
                DispatchQueue.main.async {
                    //                    loading.stopAnimating()
                    self.alert.displayAlertView(viewController: self, alertTitle: "Geocode Error", alertMessage: (error?.localizedDescription)!)
                }
            }
            if let placeMark = placeMarks?.first
            {
                let placemark: CLPlacemark = placeMark
                let coordinates: CLLocationCoordinate2D = placemark.location!.coordinate
                let pointAnnotation: MKPointAnnotation = MKPointAnnotation()
                pointAnnotation.coordinate = coordinates
                print(pointAnnotation.coordinate.latitude)
                print(pointAnnotation.coordinate.longitude)
                self.mapView?.addAnnotation(pointAnnotation)
                self.mapView?.centerCoordinate = coordinates
                self.mapView?.camera.altitude = 10000
            }
        }
    }
    
    func setUpFlowLayout(){
        
        let lineSpace: CGFloat = 4.0
        let cellWidth = (self.photoCollectionView.frame.size.width)/3
        let cellHeight = cellWidth
        print(cellWidth)
        
        photoCollectionViewFlowLayout.sectionInset = UIEdgeInsets(top:lineSpace, left:lineSpace, bottom: lineSpace, right:lineSpace)
        photoCollectionViewFlowLayout.minimumLineSpacing = lineSpace
        photoCollectionViewFlowLayout.minimumInteritemSpacing = lineSpace
        photoCollectionViewFlowLayout.itemSize = CGSize(width: cellWidth,height: cellHeight)
        photoCollectionView.reloadData()
    }
    
    func executeSearch(){
        
        if let fc = fetchedResultsController{
            do{
                try fc.performFetch()
            }
            catch let e as NSError{
                print("Error while performing a search: \n \(e) \n \(fetchedResultsController)")
                DispatchQueue.main.async {
                    self.alert.displayAlertView(viewController: self, alertTitle: "Error in executeSearch()", alertMessage: "Error while performing a search: \n \(e) \n \(self.fetchedResultsController)")
                }
            }
        }
    }
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        self.deleteAllImages()
        
        Flickr.shareInstance().getPhotosWithPages(location: location, withPageNumber: 1){(success,error) in
            
            if !success{
                DispatchQueue.main.async {
                    self.alert.displayAlertView(viewController: self, alertTitle: "Error while downloading photos in newCollection", alertMessage: (error?.localizedDescription)!)
                }
            }
            else{
                
                DispatchQueue.main.async {
                    self.getFetchResults()
                    if let fc = self.fetchedResultsController{
                        self.photoCollectionView.reloadData()
                    }
                    else{
                        DispatchQueue.main.async {
                            self.alert.displayAlertView(viewController: self, alertTitle: "Error in fetchingResultsController", alertMessage:"Found no results while fetching")
                        }
                    }
                }
                
            }
        }
    }
    
    func showAlertViewToDeleteCell(indexPath:NSIndexPath){
        let alert = UIAlertController(title:"Do you want to delete the image", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style:UIAlertActionStyle.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.default){(action: UIAlertAction!) in
            self.photoCollectionView.deleteItems(at: [indexPath as IndexPath])
            self.photoCollectionView.reloadData()
        })
        self.present(alert, animated: true, completion: nil)
    }
    
    //ColletionView Delegate and DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchedResultsController{
            return (fc.sections?.count)!
        }
        else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController{
            return fc.sections![section].numberOfObjects
        }
        else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionCell", for: indexPath) as! PhotosCollectionViewCell
        cell.loadingView.startAnimating()
        cell.loadingView.isHidden = false
        cell.imageView.backgroundColor = UIColor.lightGray
        let photo = fetchedResultsController?.object(at: indexPath) as! Photo
        print(fetchedResultsController?.object(at: indexPath) as! Photo)
        if photo.imageData != nil{
            DispatchQueue.main.async {

            cell.loadingView.stopAnimating()
            cell.loadingView.isHidden = true
            cell.imageView.image = UIImage(data: photo.imageData as! Data)
            cell.imageName = photo.name
            }
        }
        else{
            Flickr.shareInstance().downloadImageFromImageURL(imagePath: photo.urlString!){(success,data,error) in
                    
                    if success{
                        DispatchQueue.main.async {
                            
                            cell.loadingView.stopAnimating()
                            cell.loadingView.isHidden = true
                            cell.imageView.image = UIImage(data: data!)
                            cell.imageName = photo.name
                            photo.imageData = data as NSData?
                            print(photo.name)
                        }
                    }
                    else{
                        
                    }
                }
        }
        print(indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView.cellForItem(at: indexPath) != nil{
            let cell = collectionView.cellForItem(at: indexPath)
            
            if let index = selectedIndices.index(of: indexPath){
                selectedIndices.remove(at: index)
            }
            else{
                selectedIndices.append(indexPath)
            }
            
            if selectedIndices.isEmpty{
                self.deleteAllImages()
            }
            else{
                var photos = [Photo]()
                
                for indexPath in selectedIndices{
                    photos.append(fetchedResultsController?.object(at: indexPath) as! Photo)
                }
                
                for photo in photos{
                    self.stack.context.delete(photo)
                }
            }
        }
        else{
            //ShowAlert
        }
    }
    
    func deleteAllImages(){
        for photo in (fetchedResultsController?.fetchedObjects)!{
            self.stack.context.delete(photo as! NSManagedObject)
        }
    }
    
    //NSFetchedResultsController
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedPaths = [IndexPath]()
        deletedPaths = [IndexPath]()
        updatedPaths = [IndexPath]()
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            insertedPaths.append(newIndexPath!)
        case .delete:
            deletedPaths.append(indexPath!)
        case .update:
            updatedPaths.append(indexPath!)
        default:
            return
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        
        DispatchQueue.global(qos: .background).async {
    
           self.stack.performBackgroundBatchOperation(){(workerContext) in
         
            for indexPath in self.insertedPaths{
                self.photoCollectionView.insertItems(at: [indexPath])
            }
            for indexPath in self.deletedPaths{
                self.photoCollectionView.deleteItems(at: [indexPath])
            }
            
            for indexPath in self.updatedPaths{
                self.photoCollectionView.reloadItems(at: [indexPath])
            }
        }
      }
    }

}
