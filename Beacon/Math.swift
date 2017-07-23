//
//  Math.swift
//  HAL
//
//  Created by Thibault Imbert on 7/13/17.
//  Copyright © 2017 Thibault Imbert. All rights reserved.
//

import Foundation
import HealthKit

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
}

extension Double {
    /// Rounds the double to decimal places value
    func roundTo(places:Int) -> Double {
        if self == 0 { return 0.0 }
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
