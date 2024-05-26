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
                        .scaledToFit()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: proxy.size.width)
                        .clipShape(Rectangle())
                        .foregroundStyle(Color.init(uiColor: UIColor.systemBlue).opacity(0.15))
                }
                HStack(alignment: .center, content: {
                    Image(systemName: "play")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(0.5, contentMode: .fit)
                        .frame(width: proxy.size.width * 0.5)
                        .clipShape(Rectangle())
                        
                        
                        
                        
                        .foregroundStyle(Color.init(uiColor: UIColor.systemBlue))
                })
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
