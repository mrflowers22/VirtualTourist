//
//  ViewController.swift
//  Virtual Tourists
//
//  Created by Michael Flowers on 3/3/20.
//  Copyright © 2020 Michael Flowers. All rights reserved.
//

import UIKit
import MapKit

class PhotoListViewController: UIViewController {
    var pageToIncreate = 1
    let networkController = NetworkController.shared
    var annotation: MKPointAnnotation? {
        didSet {
            print("annotation was hit in the view controller")
            populateCollectionView()
        }
    }
    
    var pin: Pin? {
        didSet {
            print("pin was hit in the view controller")
            loadViewIfNeeded()
            setAnnotationFromPin()
        }
    }
    
    var coreDataPhotoImages: [UIImage]? {
        didSet {
            print("core data photo images array was hit")
        }
    }
    
    func setAnnotationFromPin(){
        guard let passedInPin = self.pin else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
            return
        }
        
        let coordinates = CLLocationCoordinate2D(latitude: passedInPin.lat, longitude: passedInPin.lon)
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinates
        
        let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: coordinates, span: span)
        mapView.region = region
        self.annotation = annotation
        mapView.addAnnotation(annotation)
    }
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        collectionView.delegate = self
        collectionView.dataSource  = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        networkController.photoImagesOfCurrentNetworkCall.removeAll()
    }
    
    func savePhotoIncell(withImage image: UIImage){
        if let imageData = image.pngData(), let pin = self.pin {
            print("inside the sync queue")
            PhotoController.createPhoto(withImageData: imageData, andWithPin: pin)
            
        } else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
            return
        }
    }
    
    func populateCollectionView(){
        guard let passedInPin = self.pin, let photos = passedInPin.photos else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
            return
        }
        if photos.count == 0 {
            print("pin has no photos so we are making network call based on pin's lat and lon")
            networkCall(lat: passedInPin.lat, lon: passedInPin.lon)
        } else {
            print("passed in pin does have photos")
            self.coreDataPhotoImages =  PinController.shared.getImageDataFromPhoto(pin: passedInPin)
            print("coreDataPhotoImages.count:  \(String(describing: self.coreDataPhotoImages?.count))")
            self.collectionView.reloadData()
        }
    }
    
    func networkCall(lat: Double, lon: Double, page: Int? = 1){
        NetworkController.shared.fetchPhotoInformationAtGeoLocation(lat: lat, lon: lon, page: page) { (photoInformationArray, error) in
            if let error = error {
                print("Error in file: \(#file) in the body of the function: \(#function)\n on line: \(#line)\n Readable Error: \(error.localizedDescription)\n Technical Error: \(error)\n")
                return
            }
            guard let returnedArray = photoInformationArray else {
                print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
                return
            }
            
            NetworkController.shared.fetchPhotos(withPhotoInformation: returnedArray) { (error) in
                if let error = error {
                    print("Error in file: \(#file) in the body of the function: \(#function)\n on line: \(#line)\n Readable Error: \(error.localizedDescription)\n Technical Error: \(error)\n")
                    return
                }
                //when function is done, it loads the array of images in pinController therefore we can populate the collectionView
                self.collectionView.reloadData()
            }
        }
    }
    
    @IBAction func loadMorePhotos(_ sender: UIBarButtonItem) {
        self.coreDataPhotoImages = nil
        networkController.photoImagesOfCurrentNetworkCall.removeAll()
        //increase page
        self.pageToIncreate += 1
        
        guard let passedInPin = self.pin else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
            return
        }
        
        networkCall(lat: passedInPin.lat, lon: passedInPin.lon, page: self.pageToIncreate)
        print("making network call with the page parameter")
    }
}

extension PhotoListViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return coreDataPhotoImages?.count ?? networkController.photoImagesOfCurrentNetworkCall.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "photoCell", for: indexPath) as! PhotoCollectionViewCell
        
        cell.photoImageView.image = UIImage(named: "placeholder")
        
        if let coreDataPhotos = coreDataPhotoImages {
            let photo = coreDataPhotos[indexPath.row]
            cell.photoImageView.image = photo
            
        } else if !networkController.photoImagesOfCurrentNetworkCall.isEmpty {
            let photo = networkController.photoImagesOfCurrentNetworkCall[indexPath.row]
            cell.photoImageView.image = photo
            self.savePhotoIncell(withImage: photo)
            
        } else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("touched photo at: \(indexPath.section) at \(indexPath.row)")
        guard let pin = self.pin, let pinPhotos = pin.photos else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
            return
        }
        if let photo = pinPhotos[indexPath.row] as? Photo {
            PhotoController.delete(photo: photo, fromPin: pin)
            print("deleted photo")
            self.populateCollectionView()
        } else {
            print("Error in file: \(#file), in the body of the function: \(#function) on line: \(#line)\n")
        }
        self.collectionView.reloadData()
    }
}

extension PhotoListViewController: MKMapViewDelegate {
    //to spruce up the annotation
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = true
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        return pinView
    }
}
