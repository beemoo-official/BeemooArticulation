import SwiftUI

/// Independent Flashcard Practice — navigate through word cards
/// with prev/next arrows, large image, word text, and speaker.
struct FlashcardScreenView: View {
    let screen: ScreenConfig
    let settings: RunnerSettings
    let onAdvance: () -> Void

    @State private var currentIndex = 0
    @State private var showCard = true

    @State private var bubbleVM: NarratedBubbleVM?
    @State private var narrationTrack = SystemNarrationTrack()

    private var stimuli: [StimulusConfig] {
        screen.stimuli ?? []
    }

    private var current: StimulusConfig? {
        guard currentIndex < stimuli.count else { return nil }
        return stimuli[currentIndex]
    }

    var body: some View {
        GeometryReader { geo in
            if let stimulus = current {
                ZStack {
                    VStack(spacing: 12) {
                        Spacer().frame(height: 54)

                        // Large word image
                        RemoteImage(filename: stimulus.wordImage)
                            .scaledToFit()
                            .frame(maxWidth: geo.size.width * 0.4, maxHeight: geo.size.height * 0.5)
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: BM.cardRadius)
                                    .fill(.white)
                                    .bmCardShadow()
                            )
                            .opacity(showCard ? 1 : 0)
                            .animation(.easeOut(duration: 0.2), value: showCard)

                        // Word + speaker
                        HStack(spacing: 10) {
                            Text(stimulus.targetWord.capitalized)
                                .font(.baloo2(30))
                                .foregroundStyle(Color.bmNavy)
                            SpeakerButton(
                                text: stimulus.audioText ?? stimulus.targetWord,
                                size: 40
                            )
                        }

                        Spacer()
                    }

                    // Navigation arrows
                    HStack {
                        // Previous
                        if currentIndex > 0 {
                            navArrow(systemName: "chevron.left") {
                                navigate(to: currentIndex - 1)
                            }
                        }

                        Spacer()

                        // Next / Done
                        if currentIndex < stimuli.count - 1 {
                            navArrow(systemName: "chevron.right") {
                                navigate(to: currentIndex + 1)
                            }
                        } else {
                            navArrow(systemName: "checkmark") {
                                onAdvance()
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    // BEEMOO bubble
                    VStack {
                        HStack {
                            Spacer().frame(width: 70)
                            if let vm = bubbleVM {
                                NarratedBubble(vm: vm, contentWidth: geo.size.width * 0.32)
                            }
                            Spacer()
                        }
                        .padding(.top, 60)
                        Spacer()
                    }

                    // Counter
                    VStack {
                        Spacer()
                        Text("\(currentIndex + 1) / \(stimuli.count)")
                            .font(.nunito(14, weight: .bold))
                            .foregroundStyle(Color.bmNavy62)
                            .padding(.bottom, 12)
                    }
                }
            }
        }
        .background { JungleBackground() }
        .onAppear { startNarration() }
        .onDisappear { narrationTrack.stop() }
    }

    // MARK: - Navigation

    private func navArrow(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(Circle().fill(Color.bmBlue))
                .bmFloatingControlShadow()
        }
        .buttonStyle(.plain)
    }

    private func navigate(to index: Int) {
        withAnimation(.easeOut(duration: 0.15)) { showCard = false }
        Task {
            try? await Task.sleep(for: .milliseconds(180))
            currentIndex = index
            withAnimation(.easeOut(duration: 0.2)) { showCard = true }
            startNarration()
        }
    }

    // MARK: - Narration

    private func startNarration() {
        let text = "Say the word."
        let vm = NarratedBubbleVM(markerText: text, narrationTrack: narrationTrack)
        vm.isNarrationOff = !settings.narrationEnabled
        self.bubbleVM = vm
        vm.startNarration()
    }
}
