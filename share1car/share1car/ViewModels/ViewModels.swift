//
//  Models.swift
//  share1car
//
//  Created by Alex Linkov on 11/1/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation
import CoreLocation



public struct S1CUserDetails {
    var UID: String?
    var phone: String?
    var photoURL: String?
    var name: String?
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
