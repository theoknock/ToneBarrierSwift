import SwiftUI
import Intents

@main
struct ToneBarrierApp: App {
    @StateObject private var appState = AppState.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    appState.setup()
                    appState.setupMediaPlayer()
                    
                    // Register the intent handlers
                    INPreferences.requestSiriAuthorization { status in
                        if status == .authorized {
                            let toggleIntent = ToggleToneBarrierIntent()
                            toggleIntent.suggestedInvocationPhrase = "Toggle Tone Barrier"
                            INInteraction(intent: toggleIntent, response: nil).donate(completion: nil)
                            
                            let pauseIntent = PauseToneBarrierIntent()
                            pauseIntent.suggestedInvocationPhrase = "Pause Tone Barrier"
                            INInteraction(intent: pauseIntent, response: nil).donate(completion: nil)
                        }
                    }
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
