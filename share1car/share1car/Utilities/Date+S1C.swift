//
//  Date+S1C.swift
//  share1car
//
//  Created by Alex Linkov on 11/19/19.
//  Copyright © 2019 SDWR. All rights reserved.
//

import Foundation

struct DateISO: Codable {
    var date: Date
}

extension Date{
    var isoString: String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(DateISO(date: self)),
        let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as?  [String: String]
            else { return "" }
        return json.first?.value ?? ""
    }
    
    
    static func ISOStringFromDate(date: Date) -> String {
        let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        return dateFormatter.string(from: date).appending("Z")
        }
    static func dateFromISOString(string: String) -> Date? {
        let dateFormatter = DateFormatter()
                dateFormatter.locale = Locale(identifier: "en_US_POSIX")
                dateFormatter.timeZone = TimeZone.autoupdatingCurrent
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return dateFormatter.date(from: string)
        }
    
}
