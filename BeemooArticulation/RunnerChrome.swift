import SwiftUI

// MARK: - Home button (top leading)

struct RunnerHomeButton: View {
    let onExit: () -> Void

    @State private var revealed = false
    @State private var isHolding = false
    @State private var holdProgress: CGFloat = 0
    @State private var hideTask: Task<Void, Never>?

    private let holdDuration: Double = 1.0

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.bmBlue)
                .frame(width: 44, height: 44)
                .overlay {
                    Circle().stroke(.white, lineWidth: 3)
                }

            // Hold progress ring
            Circle()
                .trim(from: 0, to: holdProgress)
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 44, height: 44)
                .rotationEffect(.degrees(-90))

            Image(systemName: "house.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
        }
        .onTapGesture {
            if !revealed {
                withAnimation(.easeOut(duration: 0.2)) { revealed = true }
                scheduleHide()
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isHolding else { return }
                    isHolding = true
                    hideTask?.cancel()
                    withAnimation(.linear(duration: holdDuration)) {
                        holdProgress = 1.0
                    }
                }
                .onEnded { _ in
                    if holdProgress >= 0.99 {
                        onExit()
                    } else {
                        isHolding = false
                        withAnimation(.easeOut(duration: 0.15)) { holdProgress = 0 }
                        scheduleHide()
                    }
                }
        )
        .onChange(of: holdProgress) { _, val in
            if val >= 0.99 && isHolding { onExit() }
        }
    }

    private func scheduleHide() {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.2)) {
                revealed = false
                holdProgress = 0
            }
        }
    }
}

// MARK: - Progress readout pill (bottom trailing)

struct ProgressPill: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(Color.bmYellow)
                .frame(width: 4, height: 4)

            Text("\(current) / \(total)")
                .font(.baloo2(13))
                .foregroundStyle(Color.bmNavy)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Capsule().fill(.white.opacity(0.82)))
    }
}

// MARK: - Next button (bottom centre)

struct NextButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color.bmBlue)
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                }
        }
    }
}
