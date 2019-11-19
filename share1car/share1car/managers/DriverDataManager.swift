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

import Polyline

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
    
    func fetchPreplannedCarpool(completion: @escaping result_errordescription_block) {
        
        
        self.ref.child("DateTime").child(AuthManager.shared.currentUserID()!).child("preplan").observe(.value) { (snapshot) in
            
            if let result = snapshot.value {
                completion((result as? String), nil)
            } else {
                completion(nil, nil)
            }
        }
        
    }
    
    func addPreplannedCarpool(date: Date, completion: @escaping result_errordescription_block) {
        
        self.ref.child("DateTime").child(AuthManager.shared.currentUserID()!).child("preplan").setValue(Date.ISOStringFromDate(date: date), withCompletionBlock:
            { (error, ref) in
                if error != nil {
                    completion(nil, error!.localizedDescription)
                }
                
                completion(ref, nil)
            })
    }
    
    func removePreplannedCarpool( completion: @escaping result_errordescription_block) {
        
        self.ref.child("DateTime").child(AuthManager.shared.currentUserID()!).removeValue { (error, ref) in

                if error != nil {
                    completion(nil, error!.localizedDescription)
                }
                
                completion(ref, nil)

        }
    }
    
    func setRoute(route: Route, driverID: String) {
        
        
        guard route.coordinateCount > 0 else { return }
        
        
        let routeCoordinates = route.coordinates!
        
        
        let polyline = Polyline(coordinates: routeCoordinates, levels: nil, precision: 1e6)
        
        let encodedPolyline: String = polyline.encodedPolyline
        
        self.ref.child("DriverRoutes").child(driverID).setValue(encodedPolyline);
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
        self.ref.child("DriverLocations").child(driverID).removeValue { (error, ref) in
            if error != nil {
                print(error!.localizedDescription)
            }
            
        }
        self.ref.child("DriverRoutes").child(driverID).removeValue()
    }
    
    func setCurrentLocation(location: CLLocationCoordinate2D, driverID: String) {
        self.ref.child("DriverLocations").child(driverID).setValue(([location.latitude, location.longitude])) { (error, ref) in
            
            if error != nil {
                print(error!.localizedDescription)
            }
        }
    }
}
