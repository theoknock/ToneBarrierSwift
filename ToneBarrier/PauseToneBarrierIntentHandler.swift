import SwiftUI
import Intents

class PauseToneBarrierIntentHandler: NSObject, PauseToneBarrierIntentHandling {
    
    @ObservedObject var appState = AppState.shared
    
    func handle(intent: PauseToneBarrierIntent, completion: @escaping (PauseToneBarrierIntentResponse) -> Void) {
        // Pause playback state in appState
        if appState.isPlaying {
            appState.isPlaying = false
        }
        
        // Provide a response based on the new state
        let response = PauseToneBarrierIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}
