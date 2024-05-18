//
//  File.swift
//  ToneBarrier
//
//  Created by James Alan Bush on 5/16/24.
//

import SwiftUI
import Foundation
import Combine
import Observation

@Observable class Durations {
    var durationLength:     Double = 2.0000
    var durationLowerBound: Double = 0.3125
    var durationUpperBound: Double = 1.6875
    var durationTolerance:  Double = 0.3125

    init(length: Double?, lowerBound: Double?, upperBound: Double?, tolerance: Double?) {
        self.durationLength     = length     ?? durationLength
        self.durationLowerBound = lowerBound ?? durationLowerBound
        self.durationUpperBound = upperBound ?? durationUpperBound
        self.durationTolerance  = tolerance  ?? durationTolerance
       
        guard (durationUpperBound - durationLowerBound) >= durationTolerance else {
            fatalError("\(#function) error: |durationLowerBound - durationUpperBound| < durationTolerance")
        }
    }

    func scale(oldMin: CGFloat, oldMax: CGFloat, value: CGFloat, newMin: CGFloat, newMax: CGFloat) -> CGFloat {
        return newMin + ((newMax - newMin) * ((value - oldMin) / (oldMax - oldMin)))
    }

    let serialQueue = DispatchQueue(label: "com.example.serialQueue")

    public func randomizeDurationSplits(completion: @escaping ([[Double]]) -> Void) {
        serialQueue.async { [self] in
            let dyad0harmony0: Double = Double.random(in: durationLowerBound...durationUpperBound)
            var dyad1harmony0: Double = dyad0harmony0

            repeat {
                dyad1harmony0 = Double.random(in: durationLowerBound...durationUpperBound)
            } while (abs(dyad0harmony0 - dyad1harmony0) < durationTolerance)

            let dyad0harmony1 = durationLength - dyad0harmony0
            let dyad1harmony1 = durationLength - dyad1harmony0

            let result = [[dyad0harmony0, dyad0harmony1], [dyad1harmony0, dyad1harmony1]]

            DispatchQueue.main.async {
                completion(result)
            }
        }
    }
}

struct ContentView: View {
    private var durations: Durations = Durations(length: nil, lowerBound: nil, upperBound: nil, tolerance: nil)
    @State private var results: [[[Double]]] = []

    var body: some View {
        ZStack(alignment: Alignment(horizontal: .center, vertical: .center), content: {
            List(results, id: \.self) { result in

                let diff = abs(result[0][0] - result[1][0])
                let sum = result[0][0] + result[0][1]

                let formattedDiff = String(format: "-%.4f", diff)
                let formattedSum = String(format: "+%.4f", sum)

                let diffColor = diff >= 0.3125 ? UIColor.green : UIColor.red
                let sumColor = sum == 2.0000 ? UIColor.green : UIColor.red

                let text = NSMutableAttributedString(string: "\(result[0][0])\n\(result[1][0])\n")

                let coloredDiff = NSAttributedString(
                    string: formattedDiff,
                    attributes: [.foregroundColor: diffColor]
                )
                text.append(coloredDiff)
                text.append(NSAttributedString(string: "\n"))

                let coloredSum = NSAttributedString(
                    string: formattedSum,
                    attributes: [.foregroundColor: sumColor]
                )
                text.append(coloredSum)
                //
                return Text(AttributedString(text))
                    .frame(alignment: .leading)
                    .border(.white)
                    .padding()
            }

            Button("Randomize Duration Splits") {
                durations.randomizeDurationSplits { result in
                    print(result)
                    results.append(result)
                }
            }
            .safeAreaPadding()
            .border(.white)
        })
    }
}

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
