//
//  ContentView.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/26/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        let divideValue = 2.0
        GeometryReader { proxy in
            ZStack {
                Color.clear
                HStack(spacing: 0) {
                    Image(systemName: "sun.dust")
                        .resizable()
                        .scaledToFill()
                        .frame(width: proxy.size.width / divideValue, height: proxy.size.height / divideValue)
                        .scaleEffect(0.5)
                        .clipped()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
