import SwiftUI
import IntentsUI

struct SiriButtonView: UIViewRepresentable {
    func makeUIView(context: Context) -> INUIAddVoiceShortcutButton {
        let button = INUIAddVoiceShortcutButton(style: .blackOutline)
        let intent = ToggleToneBarrierIntent()
        intent.suggestedInvocationPhrase = "Toggle ToneBarrier"
        button.shortcut = INShortcut(intent: intent)
        button.delegate = context.coordinator
        return button
    }

    func updateUIView(_ uiView: INUIAddVoiceShortcutButton, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, INUIAddVoiceShortcutButtonDelegate, INUIAddVoiceShortcutViewControllerDelegate, INUIEditVoiceShortcutViewControllerDelegate {
        var parent: SiriButtonView

        init(_ parent: SiriButtonView) {
            self.parent = parent
        }

        func present(_ addVoiceShortcutViewController: INUIAddVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
            guard let window = UIApplication.shared.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            addVoiceShortcutViewController.delegate = self
            rootViewController.present(addVoiceShortcutViewController, animated: true, completion: nil)
        }

        func present(_ editVoiceShortcutViewController: INUIEditVoiceShortcutViewController, for addVoiceShortcutButton: INUIAddVoiceShortcutButton) {
            guard let window = UIApplication.shared.windows.first,
                  let rootViewController = window.rootViewController else {
                return
            }
            editVoiceShortcutViewController.delegate = self
            rootViewController.present(editVoiceShortcutViewController, animated: true, completion: nil)
        }

        func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            controller.dismiss(animated: true, completion: nil)
        }

        func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
            controller.dismiss(animated: true, completion: nil)
        }

        func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didUpdate voiceShortcut: INVoiceShortcut?, error: Error?) {
            if let error = error {
                print("Error: \(error.localizedDescription)")
            }
            controller.dismiss(animated: true, completion: nil)
        }

        func editVoiceShortcutViewController(_ controller: INUIEditVoiceShortcutViewController, didDeleteVoiceShortcutWithIdentifier deletedVoiceShortcutIdentifier: UUID) {
            controller.dismiss(animated: true, completion: nil)
        }

        func editVoiceShortcutViewControllerDidCancel(_ controller: INUIEditVoiceShortcutViewController) {
            controller.dismiss(animated: true, completion: nil)
        }
    }
}
