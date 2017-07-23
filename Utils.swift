//
//  Utils.swift
//  Hal
//
//  Created by Thibault Imbert on 7/23/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class Utils {
    public static func getDate(unixdate: Int, timezone: String) -> DateComponents {
        let date = Date(timeIntervalSince1970: TimeInterval(unixdate))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateFormat = "yyyy-MM-dd'T'hh:mm:ss a"
        dayTimePeriodFormatter.timeZone = NSTimeZone(name: timezone) as TimeZone!
        dayTimePeriodFormatter.locale = Locale(identifier: "en_US_POSIX")
        let calendar = Calendar.current
        let comp = calendar.dateComponents([.day, .month, .year, .hour, .minute, .second], from: dayTimePeriodFormatter.date(from: dayTimePeriodFormatter.string(from: date))!)
        //print ( dayTimePeriodFormatter.string(from: date))
        return comp
    }
}

extension Double {
    func getDateStringFromUTC() -> String {
        let date = Date(timeIntervalSince1970: self)
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        
        return dateFormatter.string(from: date)
    }
}
