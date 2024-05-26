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
            ZStack(alignment: Alignment(horizontal: .center, vertical: .center), content: {
                Color.black
                HStack(spacing: 0) {
                    Image(systemName: "waveform.path")
                        .resizable()
                        .aspectRatio(1.0, contentMode: .fit)
                        .scaledToFit()
                        .clipped()
                        .foregroundStyle(Color.init(uiColor: UIColor.systemBlue).opacity(0.15))
                }
                HStack(spacing: 0) {
                    Image(systemName: "play")
                        .resizable()
                        .scaledToFit()
                        .frame(width: UIScreen.main.bounds.width * 0.5, height: UIScreen.main.bounds.height * 0.5)
//                        .aspectRatio(0.5, contentMode: .fit)
                        
                        .clipped()
                        .foregroundStyle(Color.init(uiColor: UIColor.systemBlue))
                }
            })
            .background {
                
            }
            .ignoresSafeArea()
            
        }
    }
}

#Preview {
    ContentView()
}
