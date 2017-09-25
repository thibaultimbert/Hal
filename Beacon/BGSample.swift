//
//  BGSample.swift
//  Hal
//
//  Created by Thibault Imbert on 7/18/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class BGSample: EventDispatcher
{
    
    public var value: Int = 0
    public let time: String
    public let date: String
    public var trend: String
    public var trends: [String] = ["", "\u{2191}\u{2191}", "\u{2191}", "\u{2197}", "\u{2192}", "\u{2198}", "\u{2193}", "\u{2193}\u{2193}"]
    
    init (pValue: Int, pDate: String, pTime: String, pTrend: String)
    {
        value = pValue
        date = pDate
        time = pTime
        trend = ""
    }
}

class HeartRateSample: BGSample {}
