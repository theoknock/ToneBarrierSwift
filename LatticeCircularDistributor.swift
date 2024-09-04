//
//  LatticeCircularDistributor.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 9/3/24.
//

import Foundation
import SwiftUI

class LatticeCircularDistributor {
    var randoms: [Float64] = [Float64.zero, Float64.zero]
    var boundLower: Float64
    var boundUpper: Float64
    var threshholdLeft: Float64
    var threshholdRight: Float64
    
    init(boundLower: Float64, boundUpper: Float64, threshholdLeft: Float64, threshholdRight: Float64) {
        self.boundLower = boundLower
        self.boundUpper = boundUpper
        self.threshholdLeft = threshholdLeft
        self.threshholdRight = threshholdRight
        distributeRandoms()
    }
    
    func scaledAngle(scale: Float64) -> Float64 {
        return abs(360.0 * scale)
    }
    
    func offsetAngle(startAngle: Float64, offsetDegrees: Float64) -> Float64 {
        let radians = (startAngle + offsetDegrees) * .pi / 180.0
        let sinValue = sin(radians)
        let cosValue = cos(radians)
        let angle = atan2(sinValue, cosValue) * 180.0 / .pi
        return angle + 360.0 * floor((360.0 - angle) / 360.0)
    }
    
    func description() -> String {
        return "\(randoms[0])°\t\t\(randoms[1])°"
    }
    
    func scale(min_new: Float64, max_new: Float64, val_old: Float64, min_old: Float64, max_old: Float64) -> Float64 {
        return min_new + (((val_old - min_old) * (max_new - min_new)) / (max_old - min_old))
    }
    
    func distributeRandoms() {
        let lowerRangeBoundary = scaledAngle(scale: self.boundLower)
        let upperRangeBoundary = scaledAngle(scale: self.boundUpper)
        let firstRandom = Float64.random(in: lowerRangeBoundary...upperRangeBoundary)
        
        let lowerRandomThreshold = scaledAngle(scale: 0.0625)
        let upperRandomThreshold = scaledAngle(scale: 0.0625)
        
        let secondRandomLowerRange = offsetAngle(startAngle: lowerRangeBoundary, offsetDegrees: lowerRandomThreshold)
        let secondRandomUpperRange = offsetAngle(startAngle: upperRangeBoundary, offsetDegrees: -upperRandomThreshold)
        let nextRandom = Float64.random(in: secondRandomLowerRange...secondRandomUpperRange)
        
        randoms = [scale(min_new: boundLower, max_new: boundUpper, val_old: firstRandom, min_old: 0.0, max_old: 360.0),
                   scale(min_new: boundLower, max_new: boundUpper, val_old: nextRandom, min_old: 0.0, max_old: 360.0)]
    }
}
