import SwiftUI

/// Circular speaker button that plays TTS audio on tap.
struct SpeakerButton: View {
    let text: String
    var size: CGFloat = 48

    @State private var narrationTrack = SystemNarrationTrack()
    @State private var isSpeaking = false

    var body: some View {
        Button {
            speak()
        } label: {
            Image(systemName: isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Circle().fill(Color.bmBlue))
                .bmFloatingControlShadow()
        }
        .buttonStyle(.plain)
        .onDisappear { narrationTrack.stop() }
    }

    private func speak() {
        isSpeaking = true
        narrationTrack.speak(text, onWord: { _ in }, onFinish: {
            isSpeaking = false
        })
    }
}
