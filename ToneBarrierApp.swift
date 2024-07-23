    import SwiftUI

    @main
    struct ToneBarrierApp: App {
        @StateObject private var appState = AppState()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .preferredColorScheme(.dark)
                    .environmentObject(appState)
                    .onAppear {
                        appState.setup()
                        appState.setupMediaPlayer()
                    }
                    .onChange(of: scenePhase) { newPhase in
                        switch newPhase {
                        case .active:
                            appState.didBecomeActive()
                        case .inactive:
                            appState.willResignActive()
                        case .background:
                            appState.didEnterBackground()
                        @unknown default:
                            break
                        }
                    }
            }
        }

        @Environment(\.scenePhase) private var scenePhase
    }
