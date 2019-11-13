//
//  DriverDataManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation


class DriverDataManager: NSObject {
    
    static let shared = DriverDataManager()
    var ref: DatabaseReference!

     override init(){
        ref = Database.database().reference()
    }
    
    func sendRideAccept(fromDriverID: String, toRiderID: String, status: CarpoolAcceptStatus ) {
        
        self.ref.child("RideAccepts").child(toRiderID).setValue([fromDriverID: status.rawValue])
    }
    
    
    func fetchCarpoolRequestForMyDriverID(completion: @escaping carpoolrequest_error_block) {
        self.ref.child("RouteRequests").child(AuthManager.shared.currentUserID()!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let result = snapshot.value {
                completion((result as? [String : Any] ?? [:]), nil)
            }
                        
          }) { (error) in
            completion(nil, error)
        }
    }
    
    func startObservingCarpoolRequestForMyDriverID(completion: @escaping carpoolrequest_error_block) {
        
        self.ref.child("RouteRequests").child(AuthManager.shared.currentUserID()!).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let result = snapshot.value {
                completion((result as? [String : Any] ?? [:]), nil)
            }
                        
          }) { (error) in
            completion(nil, error)
        }
    }
    
    func stopObservingCarpoolRequestForMyDriverID()  {
        
    }
    
    
    func setRoute(route: Route, driverID: String) {
        
        
        guard route.coordinateCount > 0 else { return }
        
        
        var routeCoordinates = route.coordinates!
        let polyline = MGLPolylineFeature(coordinates: &routeCoordinates, count: route.coordinateCount)
        let data: Data = polyline.geoJSONData(usingEncoding: String.Encoding.utf8.rawValue)
        let routeString =  String(data: data, encoding: .utf8)
        self.ref.child("DriverRoutes").child(driverID).setValue(routeString);
    }
    
    func getExistingRoute(driverID: String, completion: @escaping driver_route_geometry_error_block) {
        self.ref.child("DriverRoutes").child(driverID).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let result = snapshot.value {
                completion((result as! String), nil)
            }
                        
          }) { (error) in
            completion(nil, error)
        }
    }
    
    func removeRoute(driverID: String) {
        self.ref.child("DriverRoutes").child(driverID).removeValue();
    }
    
    func setCurrentLocation(location: CLLocationCoordinate2D, driverID: String) {
        self.ref.child("DriverLocations").child(driverID).setValue([location.latitude, location.longitude])
    }
}
