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
