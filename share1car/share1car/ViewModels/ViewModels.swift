//
//  Models.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import CoreLocation


enum CarpoolAcceptStatus: String {
    case accepted = "accepted"
    case rejected = "rejected"
    case confirmed = "confirmed"
    case arrived = "arrived"
}


enum CarpoolRequestStatus: String {
    case requested = "requested"
    case accepted = "accepted"
    case riderCancelled = "riderCancelled"
    case confirmed = "confirmed"
    case cancelled = "cancelled"
}


public struct S1CUserDetails {
    var UID: String?
    var phone: String?
    var photoURL: String?
    var name: String?
}


 public struct S1CCarpoolRequest {
    
    var status: CarpoolRequestStatus?
    var riderDetails: S1CUserDetails?
    
    var riderTimeToPickUpLocation: TimeInterval?
    var driverTimeToPickUpLocation: TimeInterval?
    
    var pickUpLocation: CLLocationCoordinate2D?
    var dropOffLocation: CLLocationCoordinate2D?
    
    var carpoolDistance: CLLocationDistance?
    
}

public struct S1CCarpoolSearchResult {
    
    var riderTimeToPickUpLocation: TimeInterval?
    var driverTimeToPickUpLocation: TimeInterval?
    
    var pickUpLocation: CLLocationCoordinate2D?
    var dropOffLocation: CLLocationCoordinate2D?
    
    var carpoolDistance: CLLocationDistance?
    
    var driverDetails: S1CUserDetails?
    
    func filled() -> Bool {
        
        if (riderTimeToPickUpLocation != nil &&
            driverTimeToPickUpLocation != nil &&
            pickUpLocation != nil &&
            dropOffLocation != nil &&
            driverDetails != nil &&
            driverDetails?.name != nil &&
            driverDetails?.phone != nil &&
            driverDetails?.photoURL != nil &&
            driverDetails?.UID != nil
            ) {
            
            return true
        }
        
        return false
        
    }

}
