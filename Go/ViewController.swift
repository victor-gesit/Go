//
//  ViewController.swift
//  Go
//
//  Created by Victor Idongesit on 04/09/2018.
//  Copyright © 2018 Victor Idongesit. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
    
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var toView: UIView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var navigationMethodView: UIView!
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var markerImageView: UIImageView!
    
    var selectedButton: UIButton!
    
    
    let locationManager = CLLocationManager()
    var placesClient: GMSPlacesClient!
    var autocompleteVC: GMSAutocompleteViewController!
    
    var currentLocation: CLLocationCoordinate2D? = nil
    var startLocation: CLLocationCoordinate2D? = nil
    var destinationLocation: CLLocationCoordinate2D? = nil
    var pickedPlace: GMSPlace?
    
    var navigating: Bool = false
    var startPointSelected: Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        mapView.bringSubview(toFront: fromView)
        mapView.bringSubview(toFront: toView)
        mapView.bringSubview(toFront: currentLocationButton)
        mapView.bringSubview(toFront: navigationMethodView)
        mapView.bringSubview(toFront: markerImageView)
        
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        currentLocation = locationManager.location?.coordinate
        self.mapView.animate(toLocation: currentLocation!)
        self.mapView.animate(toZoom: 18)
        
        placesClient = GMSPlacesClient.shared()
        selectedButton = fromButton
        if locationAccess() {
            print(locationManager.requestLocation())
        }
        autocompleteVC = GMSAutocompleteViewController()
        autocompleteVC.delegate = self
        
        setupView()
        getCurrentPlace(){ currentPlace in
            self.fromButton.setTitle(currentPlace, for: .normal)
        }
    }
    
    private func findMarkerCoordinates() -> CLLocation{
        let mapWith = view.bounds.width
        let mapHeight = view.bounds.height
        let mapCenterPoint = CGPoint(x: mapWith/2, y: mapHeight/2)
        let markerCoordinates = mapView.projection.coordinate(for: mapCenterPoint)
        let mapCenterLocation = CLLocation(latitude: markerCoordinates.latitude, longitude: markerCoordinates.longitude)
        return mapCenterLocation
    }
    
    private func setupView() {
        fromView.addShadows(offset: 2, radius: 2, opacity: 0.7)
        toView.addShadows(offset: 2, radius: 1, opacity: 0.7)
    }
    
    @IBAction func goFromButton(_ sender: UIButton) {
        selectedButton = sender
        self.present(autocompleteVC, animated: true, completion: nil)
    }
    
    @IBAction func goToButton(_ sender: UIButton) {
        selectedButton = sender
        self.present(autocompleteVC, animated: true, completion: nil)
    }
    
    @IBAction func currentLocationButton(_ sender: UIButton) {
        currentLocation = locationManager.location?.coordinate
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        self.mapView.animate(toLocation: currentLocation!)
        CATransaction.commit()
        
        CATransaction.begin()
        CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
        self.mapView.animate(toZoom: 18)
        CATransaction.commit()

    }
    
    private func locationAccess() -> Bool {
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .notDetermined, .denied, .restricted:
                return false
            case .authorizedAlways, .authorizedWhenInUse:
                return true
            }
        } else {
            return false
        }
    }
}


extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        pickedPlace = place
        viewController.dismiss(animated: true) {
            self.selectedButton.setTitle(place.name, for: .normal)
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        print("Error while picking place")
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        viewController.dismiss(animated: true, completion: nil)
    }
}


extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("An error occured")
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    }
    private func getCurrentPlace(completion: @escaping (String?) -> Void) {
        var currentPlace: String? = nil
        placesClient.currentPlace(callback: { (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    currentPlace = place.name
                    completion(currentPlace)
                }
            }
        })
    }
    
}

extension ViewController: GMSMapViewDelegate {
    func mapView(_ mapView: GMSMapView, willMove gesture: Bool) {
        if !navigating && !startPointSelected {
            activityIndicator.startAnimating()
        }
    }
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
    }
    
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        activityIndicator.startAnimating()
        if !navigating && !startPointSelected {
            let markerLocation = findMarkerCoordinates()
            getPlaceName(place: markerLocation) { (placeName) in
                self.activityIndicator.stopAnimating()
                if let name = placeName {
                    self.fromButton.setTitle(name, for: .normal)
                }
            }
            startLocation = markerLocation.coordinate
        }
    }
    
    private func getPlaceName(place: CLLocation, completion: @escaping(_ placeName: String?) -> Void){
        GMSGeocoder().reverseGeocodeCoordinate(place.coordinate) { (response, error) in
            if error != nil {
                completion(nil)
            }
            if let address = response?.firstResult() {
                let lines = address.lines! as [String]
                let closestAddress = lines[0]
                let addressStrings = closestAddress.split(separator: ",")
                let streetAddress = String(addressStrings[0])
                completion(streetAddress)
            } else {
                completion(nil)
            }
        }
    }
}
