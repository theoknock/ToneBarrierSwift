//
//  AngularRandomDistributor.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/25/24.
//

import Foundation

class AngularRandomDistributor {
    private var firstAngles: [Double] = []
    private var secondAngles: [Double] = []
    private var minusThresholdAngles: [Double] = []
    private var plusThresholdAngles: [Double] = []
    private var differences: [Double] = []
    let threshold: Double = 45.0
    
     
    private func generateAngles() {
        firstAngles = (0..<10).map { _ in generateRandomAngle(max: 360.0) }
        secondAngles = (0..<10).map { i in generateRandomAngle(max: firstAngles[i]) }
        minusThresholdAngles = firstAngles.map { wrapAngle($0 - threshold) }
        plusThresholdAngles = firstAngles.map { wrapAngle($0 + threshold) }
        differences = zip(secondAngles, zip(minusThresholdAngles, plusThresholdAngles)).map { calculateShortestDifference($0, $1.0, $1.1) }
        differences = (0..<10).map { i in wrapAngle(differences[i] + firstAngles[i]) }
        
        //    print("\(Int(minusThresholdAngles[index]))°") < \(Int(firstAngles[index]))° < \(Int(plusThresholdAngles[index]))° = \(Int(differences[index]))°")
            print("\(scale(oldMin: 0.0, oldMax: 360.0, value: firstAngles[0], newMin: 0.0, newMax: 1.0))")
            print("\(scale(oldMin: 0.0, oldMax: 360.0, value: differences[0], newMin: 0.0, newMax: 1.0))")

    }
    
    private func generateRandomAngle(max: Double) -> Double {
        return Double.random(in: 0...max)
    }
    
    private func calculateShortestDifference(_ angle2: Double, _ minusThreshold: Double, _ plusThreshold: Double) -> Double {
        let diffMinusThreshold = calculateShortestDistance(angle2, minusThreshold)
        let diffPlusThreshold = calculateShortestDistance(angle2, plusThreshold)
        
        return max(diffMinusThreshold, diffPlusThreshold)
    }
    
    private func calculateShortestDistance(_ angle1: Double, _ angle2: Double) -> Double {
        let diff = abs(angle1 - angle2)
        return min(diff, 360 - diff)
    }
    
    private func wrapAngle(_ angle: Double) -> Double {
        let wrapped = angle.truncatingRemainder(dividingBy: 360)
        return wrapped >= 0 ? wrapped : wrapped + 360
    }
}
