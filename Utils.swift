//
//  Utils.swift
//  Hal
//
//  Created by Thibault Imbert on 7/23/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class Utils {
    public static func getDate(unixdate: Int, format: String = "h:mm:ss") -> (Date, DateComponents, String) {
        let date = Date(timeIntervalSince1970: TimeInterval(unixdate))
        let dayTimePeriodFormatter = DateFormatter()
        dayTimePeriodFormatter.dateStyle = .medium
        dayTimePeriodFormatter.timeStyle = .medium
        dayTimePeriodFormatter.dateFormat = format
        let calendar = dayTimePeriodFormatter.calendar
        let dateString = dayTimePeriodFormatter.string(from: date)
        let components = calendar?.dateComponents([.hour, .minute, .second], from: dayTimePeriodFormatter.date(from: dateString)!)
        return (date, components!, dateString)
    }
    
    public static func getCurrentLocalDate()-> Date {
        var now = Date()
        var nowComponents = DateComponents()
        let calendar = Calendar.current
        nowComponents.year = Calendar.current.component(.year, from: now)
        nowComponents.month = Calendar.current.component(.month, from: now)
        nowComponents.day = Calendar.current.component(.day, from: now)
        nowComponents.hour = Calendar.current.component(.hour, from: now)
        nowComponents.minute = Calendar.current.component(.minute, from: now)
        nowComponents.second = Calendar.current.component(.second, from: now)
        nowComponents.timeZone = TimeZone(abbreviation: "GMT")!
        now = calendar.date(from: nowComponents)!
        return now as Date
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
