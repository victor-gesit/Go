//
//  ViewController.swift
//  Go
//
//  Created by Victor Idongesit on 04/09/2018.
//  Copyright © 2018 Victor Idongesit. All rights reserved.
//

import AVFoundation
import UIKit
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController {
    
    @IBOutlet weak var fromView: UIView!
    @IBOutlet weak var toView: UIView!
    @IBOutlet weak var currentLocationButton: UIButton!
    @IBOutlet weak var fromButton: UIButton!
    @IBOutlet weak var toButton: UIButton!
    @IBOutlet weak var drivingButton: UIButton!
    @IBOutlet weak var walkingButton: UIButton!
    
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
    
    var carMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    var walkingMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    var activeMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    var destinationMarker = GMSMarker(position: CLLocationCoordinate2D(latitude: 0, longitude: 0))
    
    var inNavigationMode = false
    var navigating = false
    var startPointSelected = false
    
    
    var lastMapBearing: Double? = 0.0
    var currentRouteBearing = 0.0
    var markerBearing: Double? = 0.0
    var lastUserBearing = 0.0
    
    var previousNavInstruction = ""
    
    var navigationMode: NavMode = .driving
    

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
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        
        placesClient = GMSPlacesClient.shared()
        selectedButton = fromButton
        startLocation = locationManager.location?.coordinate
        
        if locationAccess() {
            currentLocation = locationManager.location?.coordinate
            self.mapView.animate(toLocation: currentLocation!)
            self.mapView.animate(toZoom: 18)
            locationManager.requestLocation()
            locationManager.startUpdatingLocation()
            locationManager.startUpdatingHeading()
        }
        autocompleteVC = GMSAutocompleteViewController()
        autocompleteVC.delegate = self
        
        carMarker.icon = UIImage(named: "car")
        carMarker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        walkingMarker.icon = UIImage(named: "walking")
        destinationMarker.icon = UIImage(named: "flag")
        setupView()
        getCurrentPlace(){ currentPlace in
            self.fromButton.setTitle(currentPlace, for: .normal)
        }
    }
    
    private func findMarkerCoordinates() -> CLLocationCoordinate2D{
        let mapWith = view.bounds.width
        let mapHeight = view.bounds.height
        let mapCenterPoint = CGPoint(x: mapWith/2, y: mapHeight/2)
        let markerCoordinates = mapView.projection.coordinate(for: mapCenterPoint)
        return markerCoordinates
    }
    
    private func setupView() {
        fromView.addShadows(offset: 2, radius: 2, opacity: 0.7)
        toView.addShadows(offset: 2, radius: 1, opacity: 0.7)
        fromButton.addShadows(offset: 0.5, radius: 0.2, opacity: 0.7)
        toButton.addShadows(offset: 0.5, radius: 0.2, opacity: 0.7)
        currentLocationButton.addShadows(offset: 2, radius: 1, opacity: 0.7)
        navigationMethodView.addShadows(offset: 2, radius: 1, opacity: 0.7)
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
        if inNavigationMode {
            navigating = true
        } else {
            currentLocation = locationManager.location?.coordinate
        }
        CATransaction.begin()
        CATransaction.setValue(0.5, forKey: kCATransactionAnimationDuration)
        self.mapView.animate(toLocation: currentLocation!)
        CATransaction.commit()
        
        CATransaction.begin()
        CATransaction.setValue(1.5, forKey: kCATransactionAnimationDuration)
        self.mapView.animate(toZoom: 18)
        CATransaction.commit()
    }
    @IBAction func driveButtonTapped(_ sender: UIButton) {
        if startLocation == nil {
            showNotification(title: "Error", message: "Select a start point")
            return
        }
        if destinationLocation == nil {
            showNotification(title: "Error", message: "Select a destination")
            return
        }

        switch sender {
            case drivingButton:
                activeMarker = carMarker
                navigationMode = .driving
            case walkingButton:
                activeMarker = walkingMarker
                navigationMode = .walking
            default:
                return
        }
        
        inNavigationMode = true
        navigating = true
        UIView.animate(withDuration: 0.5) {
            self.markerImageView.alpha = 0.0
            let compassImage = UIImage(named: "compass")
            self.currentLocationButton.setImage(compassImage, for: .normal)
        }
        
        APICalls.shared.drawRoute(from: startLocation!,
                                  to: destinationLocation!,
                                  on: mapView, mode: navigationMode) { (vehicleLocation, finalDestination, direction, navInstructions) in
            
            if let vehicleLocation = vehicleLocation,
                let finalDestination = finalDestination {
                self.activeMarker.position = vehicleLocation
                self.markerBearing = direction - (self.lastMapBearing ?? 0)
                self.activeMarker.rotation = self.markerBearing!
                self.activeMarker.map = self.mapView
                
                if self.destinationMarker.map == nil {
                    self.dropMarker(marker: self.destinationMarker, at: finalDestination, on: self.mapView)
                }
            }
            if let instructions = navInstructions {
                self.sayDirections(directions: instructions)
            }
        }
    }
    
    private func showNotification(title: String, message: String) {
        let notificationController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "Okay", style: .default, handler: nil)
        notificationController.addAction(okAction)
        self.present(notificationController, animated: true, completion: nil)
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
    
    private func dropMarker( marker: GMSMarker, at location: CLLocationCoordinate2D, on mapView: GMSMapView) {
        marker.position = location
        marker.map = mapView
    }
    
    
    private func sayDirections(directions: String) {
        let speechSynthesizer = AVSpeechSynthesizer()
        if directions == previousNavInstruction { return }
        previousNavInstruction = directions
        let utterance = AVSpeechUtterance(string: directions)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        speechSynthesizer.speak(utterance)
    }
}


extension ViewController: GMSAutocompleteViewControllerDelegate {
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        pickedPlace = place
        viewController.dismiss(animated: true) {
            if self.selectedButton == self.fromButton {
                self.startPointSelected = true
                self.startLocation = place.coordinate
            }
            if self.selectedButton == self.toButton {
                self.destinationLocation = place.coordinate
            }
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        let userBearing = newHeading.trueHeading
        if (abs(userBearing - lastUserBearing) < 4) {
            return
        }
        if navigating {
            CATransaction.begin()
            CATransaction.setAnimationDuration(0.5)
            mapView.animate(toBearing: userBearing)
            CATransaction.commit()
        }
        lastUserBearing = userBearing
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if inNavigationMode {
            let location = self.startLocation ?? locations.last?.coordinate
            APICalls.shared.drawRoute(from: location!,
                                      to: destinationLocation!,
                                      on: mapView,
                                      mode: navigationMode) { (vehicleLocation, finalDestination, direction, navInstructions) in
                self.currentRouteBearing = direction
                self.currentLocation = vehicleLocation
                self.markerBearing = (direction) - self.lastMapBearing!
                if let carLocation = vehicleLocation {
                    self.moveAndCenterMarker(coordinates: carLocation, degrees: self.markerBearing!, duration: 0.5, marker: self.carMarker)
                }
                if let instructions = navInstructions {
                    self.sayDirections(directions: instructions)
                }
            }
        }
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
        if gesture {
            navigating = false
        }
        
        if !inNavigationMode && !startPointSelected {
            activityIndicator.startAnimating()
        }
    }
    func mapView(_ mapView: GMSMapView, didChange position: GMSCameraPosition) {
        lastMapBearing = position.bearing
        markerBearing = (currentRouteBearing) - lastMapBearing!
        
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.1)
        activeMarker.rotation = markerBearing!
        CATransaction.commit()
    }
    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {
        if !inNavigationMode && !startPointSelected {
            activityIndicator.startAnimating()
            let markerLocation = findMarkerCoordinates()
            getPlaceName(place: markerLocation) { (placeName) in
                self.activityIndicator.stopAnimating()
                if let name = placeName {
                    self.fromButton.setTitle(name, for: .normal)
                }
                self.activityIndicator.stopAnimating()
            }
            startLocation = markerLocation
        }
    }
    
    private func getPlaceName(place: CLLocationCoordinate2D, completion: @escaping(_ placeName: String?) -> Void){
        GMSGeocoder().reverseGeocodeCoordinate(place) { (response, error) in
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
    
    func moveAndCenterMarker(coordinates: CLLocationCoordinate2D, degrees: CLLocationDegrees, duration: Double, marker: GMSMarker) {
        // Keep Rotation Short
        CATransaction.begin()
        CATransaction.setAnimationDuration(0.5)
        marker.rotation = degrees
        CATransaction.commit()
        
        // Movement
        CATransaction.begin()
        CATransaction.setAnimationDuration(duration)
        marker.position = coordinates
        
        // Center Map View if actually driving
        if navigating {
            let camera = GMSCameraUpdate.setTarget(coordinates)
            mapView.animate(with: camera)
            mapView.animate(toViewingAngle: 30)
        }
        CATransaction.commit()
    }
}
