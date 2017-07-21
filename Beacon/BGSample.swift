//
//  BGSample.swift
//  Hal
//
//  Created by Thibault Imbert on 7/18/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation

class BGSample: EventDispatcher{
    
    public var value: Int = 0
    public let time: Date
    public var trend: Float = 0.0
    
    init (pValue: Int, pTime: Date, pTrend: Float){
        value = pValue
        time = pTime
        trend = pTrend
    }
}
