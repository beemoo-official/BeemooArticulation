import SwiftUI

/// Shared scoring bar for adult-judged production screens.
/// Shows Correct / Try Again / Skip on first attempt;
/// after a retry prompt, Try Again is hidden.
struct AdultScoringBar: View {
    let onCorrect: () -> Void
    let onTryAgain: () -> Void
    let onSkip: () -> Void
    let isRetry: Bool

    var body: some View {
        HStack(spacing: 14) {
            scoringButton(
                label: "Correct",
                icon: "checkmark",
                color: Color.bmConceptGreen,
                action: onCorrect
            )

            if !isRetry {
                scoringButton(
                    label: "Try Again",
                    icon: "arrow.counterclockwise",
                    color: Color.bmOrange,
                    action: onTryAgain
                )
            }

            scoringButton(
                label: "Skip",
                icon: "forward.fill",
                color: Color.bmNavy.opacity(0.35),
                action: onSkip
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(.ultraThinMaterial)
                .bmFloatingControlShadow()
        )
    }

    private func scoringButton(
        label: String,
        icon: String,
        color: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                Text(label)
                    .font(.nunito(14, weight: .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(color))
        }
        .buttonStyle(.plain)
    }
}
