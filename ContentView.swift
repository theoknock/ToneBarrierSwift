//
//  ContentView.swift
//  ToneBarrier
//
//  Created by Xcode Developer on 5/26/24.
//

import SwiftUI
import AVFoundation
import AVFAudio

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    let toneBarrierSapphire: Color = Color.init(hue: 206 / 360, saturation: 1, brightness: 1)
    @State private var isPlaying: Bool = false
    @State private var isPortrait: Bool = true
    
    var audioSession: AVAudioSession = AVAudioSession.sharedInstance()
    var audioSignal: AVAudioSignal = AVAudioSignal()
    
    func audio() {
        do {
            if !(audioSignal.audio_engine.isRunning) {
                try audioSignal.audio_engine.start()
            } else {
                audioSignal.audio_engine.pause()
            }
        } catch let error as NSError {
            debugPrint("\(error.localizedDescription)")
        }
        isPlaying = audioSignal.audio_engine.isRunning
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                Image(systemName: "waveform.path")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: geometry.size.width)
                    .clipShape(Rectangle())
                    .fontWeight(Font.Weight?.some(Font.Weight.regular))
                    .foregroundStyle(toneBarrierSapphire)
                    .mask {
                        MeshGradient(width: 3, height: 3, points: [
                            .init(0, 0),   .init(0.5, 0),   .init(1, 0),
                            .init(0, 0.5), .init(0.5, 0.5), .init(1, 0.5),
                            .init(0, 1),   .init(0.5, 1),   .init(1, 1)
                        ], colors: [
                            .black.opacity(0.1), .black.opacity(0.1),     .black.opacity(0.1),
                            .white.opacity(0.1), .white.opacity(0.28125), .white.opacity(0.1),
                            .black.opacity(0.1), .black.opacity(0.1),     .black.opacity(0.1)
                        ])
                    }
                Button(action: {
                    audio()
                }) {
                    Image(systemName: isPlaying ? "stop" : "play")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(1.0, contentMode: .fit)
                        .frame(width: isPortrait ? geometry.size.width * 0.35 : geometry.size.height * 0.35)
                        .clipShape(Rectangle())
                        .fontWeight(Font.Weight?.some(Font.Weight.thin))
                        .foregroundStyle(toneBarrierSapphire)
                        .shadow(color: .white.opacity(0.28125), radius: 10)
                        .offset(x: isPlaying ? -1 : 13, y: isPlaying ? 15 : 15)
                        .onAppear {
                            isPortrait = geometry.size.height > geometry.size.width
                        }
                        .onChange(of: UIScreen.main.bounds.size, {
                            isPortrait = geometry.size.height > geometry.size.width
                        })
                        .transition(.asymmetric(insertion: .scale(scale: 1.1).combined(with: .opacity), removal: .scale(scale: 0.9).combined(with: .opacity)))
                        .animation(.easeInOut(duration: 0.0), value: isPlaying)
                }
                .onAppear {
                    do {
                        try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
                        try audioSession.setActive(true)
                    } catch {
                        print("Failed to set audio session category.")
                    }
                }
            }
            .ignoresSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .preferredColorScheme(.dark)
    }
}
