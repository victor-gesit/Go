//
//  APICalls.swift
//  Go
//
//  Created by Victor Idongesit on 04/09/2018.
//  Copyright © 2018 Victor Idongesit. All rights reserved.
//

import Foundation


import Foundation
import Alamofire
import GoogleMaps
import SwiftyJSON

enum NavMode: String {
    case driving = "driving"
    case walking = "walking"
}

class APICalls {
    static var shared = APICalls()
    private static let mapsAPIKey = Utilities.valueForAPIKey(keyname: "GOOGLE_MAPS_API_KEY")
    var timeOfLastAPICall = CACurrentMediaTime()
    private var polylines: [GMSPolyline?] = []
    
    var route1 = 0
    private init() {}
    
    public func drawRoute(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D, on mapView: GMSMapView, mode: NavMode, completion: @escaping (_ vehicleLocation: CLLocationCoordinate2D?, _ finalDestination: CLLocationCoordinate2D?, _ direction: Double, _ navInstruction: String? ) -> Void){
        let now = CACurrentMediaTime()
        
        timeOfLastAPICall = now
        let origin = "\(start.latitude),\(start.longitude)"
        let destination = "\(end.latitude),\(end.longitude)"
        let navMode = mode.rawValue
        let apiKey = APICalls.mapsAPIKey
        if apiKey == nil { return }
        
        let url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(origin)&destination=\(destination)&mode=\(navMode)&key=\(apiKey!)"
        
        var polyline: GMSPolyline?
        
        Alamofire.request(url).responseJSON { response in
            do {
                let json = try JSON(data: response.data ?? Data())
                let routes = json["routes"].arrayValue
                for route in routes
                {
                    
                    if self.route1 <= 1 {
                        self.route1 += 1
                    }
                    
                    let routeOverviewPolyline = route["overview_polyline"].dictionary
                    let points = routeOverviewPolyline?["points"]?.stringValue
                    let path = GMSPath.init(fromEncodedPath: points!)
                    polyline = GMSPolyline(path: path)
                    polyline?.strokeColor = .darkGray
                    polyline?.strokeWidth = 4.0
                    polyline?.map = mapView
                    if self.polylines.count >= 1 {
                        self.polylines[self.polylines.count - 1]?.map = nil
                    }
                    self.polylines.append(polyline)
                    
                    let firstRoute = route["legs"].arrayValue[0].dictionary
                    
                    let startLocation = firstRoute?["start_location"]
                    let startLat = startLocation?["lat"].double
                    let startLong = startLocation?["lng"].double
                    
                    let endLocation = firstRoute?["end_location"]
                    let endLat = endLocation?["lat"].double
                    let endLong = endLocation?["lng"].double
                    
                    let endPoint = firstRoute?["steps"]?.arrayValue[0].dictionary
                    
                    let microPolyline = endPoint?["polyline"]?.dictionary
                    let microPoints = microPolyline?["points"]?.stringValue
                    let navInstruction = endPoint?["html_instructions"]?.stringValue
                    if let instruction = navInstruction {
                        print("Nav Instruction: \(instruction.htmlToString)")
                    }
                    
                    if let latStart = startLat,
                        let longStart = startLong,
                        let latEnd = endLat,
                        let longEnd = endLong,
                        let microPointsValue = microPoints {
                        let vehicleLocation = CLLocationCoordinate2D(latitude: latStart, longitude: longStart)
                        let finalDistination = CLLocationCoordinate2D(latitude: latEnd, longitude: longEnd)
                        
                        let destination = GMSPath.init(fromEncodedPath: microPointsValue)
                        
                        let destinationCoordinate = destination?.coordinate(at: 1)
                        if let destCoord = destinationCoordinate {
                            let direction = self.getBearing(from: vehicleLocation, to: destCoord)
                            completion(vehicleLocation, finalDistination, direction, navInstruction?.htmlToString)
                        } else {
                            completion(nil, nil, 0, "")
                        }
                        
                    } else {completion(nil, nil, 0, "")}
                    
                    
                }
            } catch let e {
                print("Error", e)
                polyline = nil
            }
        }
    }
    func getBearing(from start: CLLocationCoordinate2D, to end: CLLocationCoordinate2D) -> Double {
        
        let lat1 = start.latitude.degreesToRadians();
        let lon1 = start.longitude.degreesToRadians();
        
        let lat2 = end.latitude.degreesToRadians()
        let lon2 = end.longitude.degreesToRadians()
        
        let dLon = lon2 - lon1;
        
        let y = sin(dLon) * cos(lat2);
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
        let radiansBearing = atan2(y, x);
        
        let degreesBearing = radiansBearing.radiansToDegrees();
        
        if (degreesBearing >= 0) {
            return degreesBearing;
        } else {
            return degreesBearing + 360.0;
        }
    }
}

extension CLLocationDegrees {
    func degreesToRadians() -> Double {
        return self * .pi / 180
    }
    func radiansToDegrees() -> Double {
        return self * 180 / .pi
    }
}

extension String {
    var htmlToAttributedString: NSAttributedString? {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue], documentAttributes: nil)
        } catch {
            return NSAttributedString()
        }
    }
    var htmlToString: String {
        return htmlToAttributedString?.string ?? ""
    }
}
