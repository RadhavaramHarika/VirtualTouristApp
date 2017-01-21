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
    var location: Location!
    var placeName:String!
    @IBOutlet weak var mapView: MKMapView!
    let stack = (UIApplication.shared.delegate as! AppDelegate).stack
    let alert = AlertViewController()
    var count = Int()
    
    var reloadCollectionView: Bool = true
    
    var blockOperations: [BlockOperation] = []
    
    var photosArray: [Photo]!
//    var insertedPaths: [IndexPath]!
//    var deletedPaths: [IndexPath]!
//    var updatedPaths: [IndexPath]!
    var selectedIndices = [IndexPath]()
    
    var fetchResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchResultsController?.delegate = self
            let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
            fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),NSSortDescriptor(key: "urlString", ascending: false)]
            
            // Create the FetchedResultsController
            fetchResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
            executeSearch()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        mapView.delegate = self
        
        self.fetchResultsController?.delegate = self
        self.navigationController?.navigationBar.isHidden = false
        self.view.bringSubview(toFront: bottomToolBar)
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),NSSortDescriptor(key: "urlString", ascending: false)]
        //Create the FetchedResultsController
        fetchResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        setUpMapView()
        setUpFlowLayout()
        photoCollectionView.reloadData()
    }
    
    func getFetchResults(){
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")
        fr.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true),NSSortDescriptor(key: "urlString", ascending: true),NSSortDescriptor(key: "imageData", ascending: true)]
        //         Create the FetchedResultsController
        fetchResultsController = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
    }
    
    func setUpMapView(){
        
        let annotation = self.location
        let place = self.placeName
        let geoCoder = CLGeocoder()
        geoCoder.geocodeAddressString(place!) {(placeMarks, error) in
            
            if error != nil
            {
                DispatchQueue.main.async {
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
        
        if let fc = fetchResultsController{
            do{
                try fc.performFetch()
            }
            catch let e as NSError{
                print("Error while performing a search: \n \(e) \n \(fetchResultsController)")
                DispatchQueue.main.async {
                    self.alert.displayAlertView(viewController: self, alertTitle: "Error in executeSearch()", alertMessage: "Error while performing a search: \n \(e) \n \(self.fetchResultsController)")
                }
            }
        }
    }
    
    @IBAction func newCollectionPressed(_ sender: Any) {
        self.deleteAllImages()
        var flag = 1
        
        if count == 1{
            flag = 2
            count += 1
        }
        else{
            flag += 1
        }
        
        Flickr.shareInstance().getPhotosWithPages(location: location, withPageNumber: flag){(success,error) in
            
            if !success{
                DispatchQueue.main.async {
                    self.alert.displayAlertView(viewController: self, alertTitle: "Error while downloading photos in newCollection", alertMessage: (error?.localizedDescription)!)
                }
            }
            else{
                
                DispatchQueue.main.async {
//                    self.getFetchResults()
                    if let fc = self.fetchResultsController{
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

    
    //ColletionView Delegate and DataSource
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let fc = fetchResultsController{
            return (fc.sections?.count)!
        }
        else{
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchResultsController{
            print(fc.sections![section].numberOfObjects)
            return fc.sections![section].numberOfObjects
        }
        else{
            return 0
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotosCollectionCell", for: indexPath) as! PhotosCollectionViewCell
        configureCell(cell: cell, atIndexPath: indexPath)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        let cell = collectionView.cellForItem(at: indexPath)
        let cellPhoto = fetchResultsController?.object(at: indexPath) as! Photo
        
        if let index = selectedIndices.index(of: indexPath){
            selectedIndices.remove(at: index)
        }
        else{
            selectedIndices.append(indexPath)
        }
        
        let alert = UIAlertController(title:"Virtual Tourist", message: "Do you want to delete this cell?", preferredStyle: UIAlertControllerStyle.alert)
        alert.addAction(UIAlertAction(title: "Cancel", style:.cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style:.default, handler:{(action: UIAlertAction!) in
            
            
            }))
            self.present(alert, animated: true, completion: nil)
        
    }
    
    func configureCell(cell: PhotosCollectionViewCell, atIndexPath indexPath: IndexPath){
        
        let cellPhoto = fetchResultsController?.object(at: indexPath) as! Photo
        
        cell.imageName = cellPhoto.name
        cell.loadingView.startAnimating()
        cell.loadingView.isHidden = false
        if cellPhoto.imageData == nil{
          if cellPhoto.urlString != nil{
            Flickr.shareInstance().downloadImageFromImageURL(imagePath: cellPhoto.urlString!){(success,data,error) in
            
                if error != nil{
                    DispatchQueue.main.async {
                        self.alert.displayAlertView(viewController: self, alertTitle: "Error while downloading imageData", alertMessage: (error?.localizedDescription)!)
                    }
                }
                else{
                    cell.imageView.image = UIImage(data: data!)
                    cell.loadingView.stopAnimating()
                    cell.loadingView.isHidden = true
                    cellPhoto.imageData = data as NSData?
                    self.stack.save()
                    
                    DispatchQueue.main.async {
                        self.photoCollectionView.reloadItems(at: [indexPath])
                    }
                }
            }
          }else{
            DispatchQueue.main.async {
                self.alert.displayAlertView(viewController: self, alertTitle: "No image", alertMessage: "ImageUrl is nil,try again?")
            }
          }
        }
        else{
            cell.imageView.image = UIImage(data: cellPhoto.imageData as! Data)
            cell.loadingView.stopAnimating()
            cell.loadingView.isHidden = true
        }
        
       
    }
    
    func deleteAllImages(){
        for photo in (self.fetchResultsController?.fetchedObjects)!{
            self.stack.context.delete(photo as! Photo)
            self.stack.save()
        }
    }
    
    func deleteSelectedImages(){
        if self.selectedIndices.isEmpty{
            self.deleteAllImages()
        }
        else{
            var photos = [Photo]()
            
            for indexPath in self.selectedIndices{
                photos.append(self.fetchResultsController?.object(at: indexPath) as! Photo)
            }
            for photo in photos{
                self.stack.context.delete(photo)
                print("Deleted the coressponding photo")
                self.stack.save()
            }
        }
    }
    
    //NSFetchedResultsController
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
//        insertedPaths = [IndexPath]()
//        deletedPaths = [IndexPath]()
//        updatedPaths = [IndexPath]()
        reloadCollectionView = false
        blockOperations.removeAll(keepingCapacity: true)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        switch (type) {
        case .insert:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet)
                }
            }))
        case .delete:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet)
                }
            }))
        case .update:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet)
                }
            }))
        case .move:
            print("This is not required")
            break
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch(type) {
        case .insert:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.insertItems(at: [newIndexPath!])
                }
            }))

//            self.insertedPaths.append(newIndexPath!)
        case .delete:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.deleteItems(at: [indexPath!])
                }
            }))
//            self.deletedPaths.append(indexPath!)
        case .update:
            self.blockOperations.append(BlockOperation(block: {[weak self] in
                
                if let this = self{
                    this.photoCollectionView.reloadItems(at: [indexPath!])
                }
            }))
//            self.updatedPaths.append(indexPath!)
        case .move:
            print("this is not required")
            break
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        if reloadCollectionView{
            photoCollectionView.reloadData()
        }
        else{
            photoCollectionView.performBatchUpdates({() -> Void in
                for operation in self.blockOperations{
                    operation.start()
                }
            }, completion: {(done) in
            
                self.blockOperations.removeAll(keepingCapacity: false)
            })

        }
    }


}
