//
//  Converters.swift
//  share1car
//
//  Created by Alex Linkov on 11/7/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import UIKit
import CoreLocation
import MapboxDirections
import MapboxCoreNavigation
import MapboxNavigation

class Converters: NSObject {
    
   class func getFormattedDate(date: Date, format: String) -> String {
            let dateformat = DateFormatter()
            dateformat.dateFormat = format
            return dateformat.string(from: date)
    }
    
    
    
    class func notificationTypeFromNotificationUserInfo(userInfo: [AnyHashable : Any]) -> String {
        let info = Converters.userInfoFromRemoteNotification(userInfo: userInfo)
        let title = info.title
        let body = info.body
        
        var notificationType = "NA"
        
        
        // RideRequests
        if title == "Du hast eine neue Mitfahranfrage!" && body == "Klick hier, um sie zu sehen." {
            notificationType = "requested"
        }
        
        if title == "Der Mitfahrer hat die Anfrage zurückgezogen" {
            notificationType = "riderCancelled"
        }
        
        // RideAccepts
        if title == "Deine Mitfahranfrage wurde bestätigt" {
            notificationType = "accepted"
        }
        
        if title == "Deine Mitfahranfrage wurde abgelehnt" {
            notificationType = "rejected"
        }
        
        
        if title == "Deine Mitfahranfrage wurde arrived" {
            notificationType = "arrived"
        }
        
        
        return notificationType
    }
    
  
    class func latLongCoordinateToAndroidCompatibleCoordinateArray(coord: CLLocationCoordinate2D) -> [Double] {
     
        return [coord.longitude,coord.latitude]
    }

   class func androidCompatibleLongLatToLatLongCoordinateArray(coordsArray: [Double]) -> [Double] {
    
        return [coordsArray[1],coordsArray[0]]
   }
    
    class func androidCompatibleLongLatToLatLongCoordinates(coordsArray: [Double]) -> CLLocationCoordinate2D {
     
         return CLLocationCoordinate2D(latitude: coordsArray[1], longitude: coordsArray[0])
    }
    
    
  class func userInfoFromRemoteNotification(userInfo: [AnyHashable : Any]) -> (title: String, body: String) {
        var info = (title: "", body: "")
        guard let aps = userInfo["aps"] as? [String: Any] else { return info }
        guard let alert = aps["alert"] as? [String: Any] else { return info }
        let title = alert["title"] as? String ?? ""
        let body = alert["body"] as? String ?? ""
        info = (title: title, body: body)
        return info
    }
}
