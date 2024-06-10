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
    var boundLower: Float64
    var boundUpper: Float64
      
    var randoms: [Float64] = [Float64.zero, Float64.zero]
    var threshholdLeft: Float64
    var threshholdRight: Float64
    
    func scaledAngle(scale: Float64) -> Float64 {
        return Float64(abs(360.0 * scale))
    }

    func offsetAngle(startAngle: Float64, offsetDegrees: Float64) -> Float64 {
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
    
    func scale(min_new: Float64, max_new: Float64, val_old: Float64, min_old: Float64, max_old: Float64) -> Float64 {
        let val_new = min_new + ((((val_old - min_old) * (max_new - min_new))) / (max_old - min_old));
        return val_new;
    }
    
    func distributeRandoms(randoms: inout [Float64]) -> (Void) {
        let lowerRangeBoundary: Float64 = scaledAngle(scale: 0.0625)
        let upperRangeBoundary: Float64 = scaledAngle(scale: 0.9375)
        //print("lowerRangeBoundary == \(lowerRangeBoundary)")
        //print("upperRangeBoundary == \(upperRangeBoundary)")
        let firstRandom: Float64        = Float64.random(in: lowerRangeBoundary...upperRangeBoundary)
        //print("firstRandom == \(firstRandom)")
        
        let lowerRandomThreshold: Float64 = scaledAngle(scale: 0.0625)
        let upperRandomThreshold: Float64 = scaledAngle(scale: 0.0625)
        //print("lowerRandomThreshold == \(lowerRandomThreshold)")
        //print("upperRandomThreshold == \(upperRandomThreshold)")
        
        // get the actual lowerRangeBoundary and the relative lowerRandomThreshold and use offset func to calculate new lower bounds
        let secondRandomLowerRange: Float64 = Float64(offsetAngle(startAngle: lowerRangeBoundary, offsetDegrees: lowerRandomThreshold))
        let secondRandomUpperRange: Float64 = Float64(offsetAngle(startAngle: upperRangeBoundary, offsetDegrees: -upperRandomThreshold))
        //print("secondRandomLowerRange == \(secondRandomLowerRange)")
        //print("secondRandomUpperRange == \(secondRandomUpperRange)")
        let nextRandom: Float64 = Float64.random(in: secondRandomLowerRange...secondRandomUpperRange)
        //print("nextRandom == \(nextRandom)")
        let adjustedSecondRandom: Float64 = Float64(offsetAngle(startAngle: nextRandom, offsetDegrees: firstRandom))
        //print("adjustedSecondRandom == \(adjustedSecondRandom)")
    
        randoms = [scale(min_new: 0.0, max_new: 1.0, val_old: firstRandom, min_old: 0.0, max_old: 360.0),
                   scale(min_new: 0.0, max_new: 1.0, val_old: nextRandom, min_old: 0.0, max_old: 360.0)]
        //print("randoms == \(randoms)")
    }


    init(boundLower: Float64, boundUpper: Float64, threshholdLeft: Float64, threshholdRight: Float64) {
        self.boundLower = boundLower
        self.boundUpper = boundUpper
        
        self.threshholdLeft = threshholdLeft
        self.threshholdRight = threshholdRight
        
        distributeRandoms(randoms: &self.randoms)
    }
}

