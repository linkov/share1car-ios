//
//  PriceCalculation.swift
//  share1car
//
//  Created by Alex Linkov on 11/4/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation

class PriceCalculation: NSObject {
    
    
    func driverFeeForDistance(travelDistance: Int) -> Float {
        
        return 0.00
    }
    
    
    func driverFeeStringValue(fee: Float) -> String {
        
        return "0.00"
    }
    
//    private String calculateDriverFee(int travelDistanceInt, DecimalFormat df) {
//        DecimalFormat df2 = new DecimalFormat("#.##");
//        df.setRoundingMode(RoundingMode.HALF_UP);
//
//        Double roundedPrice;
//        if (0 <= travelDistanceInt && travelDistanceInt < 4) {
//            roundedPrice = 1.0;
//        } else if (4 <= travelDistanceInt && travelDistanceInt < 11) {
//            roundedPrice = 1 + 0.2 * (travelDistanceInt - 4);
//        } else if (11 <= travelDistanceInt && travelDistanceInt < 21) {
//            roundedPrice = 1 + 0.2 * 7 + 0.15 * (travelDistanceInt - 10);
//        } else /*(21 <= travelDistanceInt) */ {
//            roundedPrice = 1 + 0.2 * 7 + 0.15 * 10 + 0.10 * (travelDistanceInt - 20);
//        }
//
//        String finalPrice = df2.format(roundedPrice);
//
//        return finalPrice;
//    }

}
