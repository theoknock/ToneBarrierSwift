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
    
    let toneBarrierSapphire: Color = Color.init(hue: 206 / 360, saturation: 1, brightness: 1)
    @State private var isPlaying: Bool = false
    
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
        GeometryReader { proxy in
            ZStack(alignment: Alignment(horizontal: .center, vertical: .center), content: {
                Color.black
                Image(systemName: "waveform.path")
                    .resizable()
                    .scaledToFit()
                    .aspectRatio(1.0, contentMode: .fit)
                    .frame(width: proxy.size.width)
                    .clipShape(Rectangle())
                    .foregroundStyle(toneBarrierSapphire.opacity(0.15))
                Button(action: {
                    audio()
                }) {
                    Image(systemName: isPlaying ? "stop" : "play")
                        .resizable()
                        .scaledToFit()
                        .aspectRatio(0.35, contentMode: .fit)
                        .frame(width: proxy.size.width * 0.35)
                        .clipShape(Rectangle())
                        .fontWeight(Font.Weight?.some(Font.Weight.thin))
                        .foregroundStyle(toneBarrierSapphire)
                        .shadow(color: toneBarrierSapphire.opacity(0.15), radius: 10)
                }
                .onAppear {
                    do {
                        try audioSession.setCategory(.playback, mode: .default, policy: .longFormAudio)
                        try audioSession.setActive(true)
                    } catch {
                        print("Failed to set audio session category.")
                    }
                }
            })
            .ignoresSafeArea()
        }
    }
}

#Preview {
    ContentView()
}
