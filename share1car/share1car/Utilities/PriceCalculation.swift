//
//  PriceCalculation.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation

class PriceCalculation: NSObject {
    
    
   public class func driverFeeStringForDistance(travelDistance: Double) -> String {
        
    let price = driverFeeForDistance(travelDistance: travelDistance / 1000)
    let priceString = driverFeeStringValue(fee: price)
    return priceString
    
    }
    
    
   private class func driverFeeForDistance(travelDistance: Double) -> Double {
        

        var roundedPrice: Double
        if (0 <= travelDistance && travelDistance < 4) {
            roundedPrice = 1.0;
        } else if (4 <= travelDistance && travelDistance < 11) {
            roundedPrice = 1 + 0.2 * Double(travelDistance - 4);
        } else if (11 <= travelDistance && travelDistance < 21) {
            roundedPrice = 1 + 0.2 * 7 + 0.15 * Double(travelDistance - 10);
        } else /*(21 <= travelDistanceInt) */ {
            roundedPrice = 1 + 0.2 * 7 + 0.15 * 10 + 0.10 * Double(travelDistance - 20);
        }


        return roundedPrice
    }
    
    
   private class func driverFeeStringValue(fee: Double) -> String {
        let str:String = String(format:"%.2f", fee)
        return str
    }
    

}
