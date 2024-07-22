import SwiftUI
import Intents

class ToggleToneBarrierIntentHandler: NSObject, ToggleToneBarrierIntentHandling {
    
    @ObservedObject var appState = AppState.shared
    
    func handle(intent: ToggleToneBarrierIntent, completion: @escaping (ToggleToneBarrierIntentResponse) -> Void) {
        // Toggle playback state in appState
        appState.isPlaying.toggle()
        
        // Provide a response based on the new state
        let response = ToggleToneBarrierIntentResponse(code: .success, userActivity: nil)
        completion(response)
    }
}
