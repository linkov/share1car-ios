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
    
    func setRideAccept(fromDriverID: String, toRiderID: String, status: CarpoolAcceptStatus ) {
        
        self.ref.child("RideAccepts").child(toRiderID).setValue([fromDriverID: status.rawValue])
    }
    
    func setRequestAccept(fromDriverID: String, toRiderID: String, status: CarpoolRequestStatus ) {
        
        self.ref.child("RouteRequests").child(fromDriverID).child("status").setValue(status.rawValue)
    }
    
    
    func observeCarpoolRequestForMyDriverID(completion: @escaping carpoolrequest_riderID_error_block) {
        self.ref.child("RouteRequests").child(AuthManager.shared.currentUserID()!).observe( .value, with: { (snapshot) in
            
            if let result = snapshot.value as? [String : Any] {
                
                let status = result["status"] as! String
                let riderID = result["RiderID"] as! String
                let dropOff = result["RDrop"]! as! [Double]
                let pickUp = result["RLoc"]! as! [Double]
                
                var request = S1CCarpoolRequest()
                request.status = CarpoolRequestStatus(rawValue: status)
                request.pickUpLocation = Converters.androidCompatibleLongLatToLatLongCoordinates(coordsArray: pickUp)
                request.dropOffLocation = Converters.androidCompatibleLongLatToLatLongCoordinates(coordsArray: dropOff)
                
    
                completion(request, riderID, nil)
            }
                        
          }) { (error) in
            completion(nil,nil, error)
        }
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
        
        let androidCoordArray = Converters.latLongCoordinateToAndroidCompatibleCoordinateArray(coord: location)
        
        self.ref.child("DriverLocations").child(driverID).setValue(androidCoordArray) { (error, ref) in
            
            if error != nil {
                print(error!.localizedDescription)
            }
        }
    }
}
