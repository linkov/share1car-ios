//
//  RiderDataManager.swift
//  share1car
//
//  Created by Alex Linkov on 11/7/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation


class RiderDataManager: NSObject {
    
    static let shared = RiderDataManager()
    var ref: DatabaseReference!
    var liveDriversLocations: [String : Any]?

     override init() {
        ref = Database.database().reference()
    }
    
    func cancelCarpool(driverID: String, riderID: String, completion: @escaping result_errordescription_block) {
        
        self.ref.child("RouteRequests").child(driverID).child("status").setValue("riderCancelled") { (error, ref) in
            if error != nil {
                completion(nil,error?.localizedDescription)
                return
            }
            
            self.ref.child("RideAccepts").child(riderID).child(driverID).removeValue { (error, ref) in
                if error != nil {
                    completion(nil,error?.localizedDescription)
                    return
                }
            }
            
            completion(true,nil)
            
        }
        
        
    }

    func requestCarpool(pickUpLocation: CLLocationCoordinate2D, dropOffLocation: CLLocationCoordinate2D, driverID: String) {
        
        let riderID = AuthManager.shared.currentUserID()!
        let riderPickUp = [pickUpLocation.latitude, pickUpLocation.longitude]
        let riderDropOff = [dropOffLocation.latitude, dropOffLocation.longitude]
        
        let request = [
            "RiderID": riderID,
            "RiderPickupLocation": riderPickUp,
            "RiderDropoffLocation": riderDropOff,
            "DoReroute": false,
            "status": "requested"
            ] as [String : Any]
        
        
        self.ref.child("RouteRequests").child(driverID).updateChildValues(request)
    }
    
    
    func lastLocationForDriver(driverID: String) -> CLLocationCoordinate2D? {
        
        guard liveDriversLocations != nil && liveDriversLocations!.count > 0 else {
            return nil
        }
        
        let driverLocations = liveDriversLocations![driverID] as! [Double]
        let latitude = driverLocations[0]
        let longitude =  driverLocations[1]
        
        let coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return coordinates
        
        
    }
    
    func getDriversLocationa(updates: @escaping drivers_locations_block) {
        
        
        self.ref.child("DriverLocations").observe(DataEventType.value) { (DataSnapshot) in
            
            var resultDict = DataSnapshot.value as? [String : Any] ?? [:]
            
            if AuthManager.shared.currentUserID() != nil {

                resultDict = resultDict.filter({ (key, value) -> Bool in
                    return key != AuthManager.shared.currentUserID()!
                })
            }
            

            self.liveDriversLocations = resultDict
        
            updates(resultDict)
            print(resultDict)

        }
    }
    
    func getAvailableDriverRoutes(updates: @escaping routes_geometries_block) {
        self.ref.child("DriverRoutes").observe(DataEventType.value) { (DataSnapshot) in
            
            let resultDict = DataSnapshot.value as? [String : String] ?? [:]
            
            print(resultDict)
            updates(resultDict)

        }
    }
    
    
}
