//
//  LineChartFormatter.swift
//  Hal
//
//  Created by Thibault Imbert on 7/26/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import UIKit
import Foundation
import Charts

@objc(LineChartFormatter)
public class LineChartFormatter: NSObject, IAxisValueFormatter{
    
    var months: [String]! = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        
        return months[Int(value)]
    }
}
