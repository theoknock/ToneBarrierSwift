//
//  CircularLatticeDistribution.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 6/5/24.
//

import Foundation

import Foundation
import SwiftUI
import Combine
import Observation

@Observable class CircularLatticeDistribution {
    var boundLower: Double
    var boundUpper: Double
      
    var randoms: [Double] = [Double.zero, Double.zero]
    var threshholdLeft: Double
    var threshholdRight: Double
    
    func scaledAngle(scale: Double) -> Double {
        return Double(abs(360.0 * scale))
    }

    func offsetAngle(startAngle: Double, offsetDegrees: Double) -> Double {
        let radians = (startAngle + offsetDegrees) * .pi / 180.0
        let sinValue = sin(radians)
        let cosValue = cos(radians)
        let angle = atan2(sinValue, cosValue) * 180.0 / .pi
        
        let wrappedAngle = angle + 360.0 * floor((360.0 - angle) / 360.0)
        return wrappedAngle
    }
    
    func description() -> String {
        return String("\(randoms[0])°\t\t\(randoms[1])°")
    }
    
    func scale(min_new: Double, max_new: Double, val_old: Double, min_old: Double, max_old: Double) -> Double {
        let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
        return val_new;
    }
    
    func distributeRandoms(randoms: inout [Double]) -> (Void) {
        let lowerRangeBoundary: Double = scaledAngle(scale: boundLower)
        let upperRangeBoundary: Double = scaledAngle(scale: boundUpper)
        //print("lowerRangeBoundary == \(lowerRangeBoundary)")
        //print("upperRangeBoundary == \(upperRangeBoundary)")
        let firstRandom: Double        = Double.random(in: lowerRangeBoundary...upperRangeBoundary)
        //print("firstRandom == \(firstRandom)")
        
        let lowerRandomThreshold: Double = scaledAngle(scale: threshholdLeft)
        let upperRandomThreshold: Double = scaledAngle(scale: threshholdRight)
        //print("lowerRandomThreshold == \(lowerRandomThreshold)")
        //print("upperRandomThreshold == \(upperRandomThreshold)")
        
        // get the actual lowerRangeBoundary and the relative lowerRandomThreshold and use offset func to calculate new lower bounds
        let secondRandomLowerRange: Double = Double(offsetAngle(startAngle: lowerRangeBoundary, offsetDegrees: lowerRandomThreshold))
        let secondRandomUpperRange: Double = Double(offsetAngle(startAngle: upperRangeBoundary, offsetDegrees: upperRandomThreshold))
        //print("secondRandomLowerRange == \(secondRandomLowerRange)")
        //print("secondRandomUpperRange == \(secondRandomUpperRange)")
        let nextRandom: Double = Double.random(in: secondRandomLowerRange...secondRandomUpperRange)
        //print("nextRandom == \(nextRandom)")
        let adjustedSecondRandom: Double = Double(offsetAngle(startAngle: nextRandom, offsetDegrees: firstRandom))
        //print("adjustedSecondRandom == \(adjustedSecondRandom)")
    
        randoms = [scale(min_new: 0.0, max_new: 1.0, val_old: firstRandom, min_old: 0.0, max_old: 360.0),
                   scale(min_new: 0.0, max_new: 1.0, val_old: nextRandom, min_old: 0.0, max_old: 360.0)]
        //print("randoms == \(randoms)")
    }


    init(boundLower: Double, boundUpper: Double, threshholdLeft: Double, threshholdRight: Double) {
        self.boundLower = boundLower
        self.boundUpper = boundUpper
        
        self.threshholdLeft = threshholdLeft
        self.threshholdRight = threshholdRight
        
        distributeRandoms(randoms: &self.randoms)
    }
}

