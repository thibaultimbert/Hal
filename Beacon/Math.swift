//
//  Math.swift
//  HAL
//
//  Created by Thibault Imbert on 7/13/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import HealthKit
import Charts

class Math {
    
    static func computeAverage (samples: [BGSample]) -> Double {
        if (samples.count == 0) { return 0.0 }
        var sum: Double = 0
        let total: Double = Double (samples.count)
        for sample in samples {
            sum += Double(sample.value)
        }
        return ( sum / total )
    }
    
    static func computeSD(samples: [BGSample]) -> Double {
        let mean: Double = Math.computeAverage(samples: samples)
        var difference: Double
        var absoluteDifference: Double
        var squaredDifference: Double
        var sum: Double = 0.0
        let total: Double = Double (samples.count)
        for sample in samples {
            difference = mean - Double (sample.value)
            absoluteDifference = abs(difference)
            squaredDifference = pow(absoluteDifference, 2)
            sum += squaredDifference
        }
        return (sum / total).squareRoot()
    }

    static func A1C(samples: [BGSample]) -> Double {
        return ( (46.7 + Math.computeAverage(samples: samples)) / 28.7 )
    }
    
    static func computeHighBG (samples: [BGSample]) -> [BGSample] {
        let highBG: Double = 150.0
        return samples.filter { Double($0.value) > highBG }
    }
    
    static func computeLowBG (samples: [BGSample]) -> [BGSample] {
        let lowBG: Double = 80
        return samples.filter { Double($0.value) < lowBG }
    }
    
    static func computeNormalRangeBG (samples: [BGSample]) -> [BGSample] {
        let lowBG: Double = 80
        let highBG: Double = 150.0
        return samples.filter { Double($0.value) > lowBG && Double($0.value) < highBG }
    }
    
    static func sqrt (samples: [Double]) -> [Double] {
        return samples.map({(value: Double) -> Double in return value.squareRoot()})
    }
    
    static func multiply (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 * $1 }
    }
    
    static func add (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 + $1 }
    }
    
    static func subtract (a: [Double], b: [Double]) -> [Double] {
        return zip(a, b).map { $0 + $1 }
    }
    
    static func transpose (samples: [Double]) -> [[Double]] {
        var buffer: [[Double]] = []
        for i in samples {
            var temp: [Double] = []
            temp.append(i)
            temp.append(i)
            buffer.append(temp)
        }
        return buffer;
    }
    
    static func gradient(samples: [Double]) -> [Double] {
        var buffer: [Double] = []
        let end = samples.count-1
        buffer.append((samples[1] - samples[0])/1)
        for i in 1...end-1 {
            buffer.append ((samples[i+1] - samples[i-1])/2)
        }
        buffer.append((samples[samples.count-1] - samples[samples.count-2])/1)
        return buffer
    }
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        if self == 0 { return 0.0 }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
