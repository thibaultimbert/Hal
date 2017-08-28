//
//  BGSample.swift
//  Hal
//
//  Created by Thibault Imbert on 7/18/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class BGSample: NSObject, EventDispatcher, NSCoding {
    
    public var value: Int = 0
    public let time: Int
    public var trend: String
    public var trends: [String] = ["\u{2913}", "\u{2191}\u{2191}", "\u{2192}", "\u{2197}", "\u{2192}", "\u{2198}", "\u{2912}", "\u{2912}"]
    
    required init(coder aDecoder: NSCoder) {
        self.value = aDecoder.decodeObject(forKey: "value") as! Int
        self.time = aDecoder.decodeObject(forKey: "time") as! Int
        self.trend = (aDecoder.decodeObject(forKey: "trend") as! NSString) as String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.value, forKey: "value")
        aCoder.encode(self.time, forKey: "time")
        aCoder.encode(self.trend, forKey: "trend")
    }
    
    init (pValue: Int, pTime: Int, pTrend: Int){
        value = pValue
        time = pTime
        trend = trends[pTrend]
    }
}

class HeartRateSample: BGSample {}
