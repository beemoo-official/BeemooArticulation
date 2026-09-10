import SwiftUI

struct ActivityListView: View {
    let umbrellaKey: String
    @Binding var path: NavigationPath
    @Environment(APIClient.self) private var apiClient

    private var umbrella: Umbrella? {
        apiClient.catalog.umbrellas.first { $0.key == umbrellaKey }
    }

    private var activities: [Activity] {
        apiClient.catalog.activities(for: umbrellaKey)
    }

    private let headerGradient = LinearGradient(
        colors: [Color(hex: "DCEBFB"), Color.bmIce],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                activityRows
            }
        }
        .background(Color.bmIce)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            BackButton {
                path.removeLast()
            }

            Text(umbrella?.title ?? "Activities")
                .font(.baloo2(21))
                .foregroundStyle(umbrella?.inkColor ?? .bmNavy)

            Text(progressSubtitle)
                .font(.nunito(12))
                .foregroundStyle(Color.bmNavy.opacity(0.60))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 44)
        .padding(.horizontal, BM.sectionPadH)
        .padding(.bottom, 16)
        .background(headerGradient)
    }

    private var progressSubtitle: String {
        let live = activities.filter(\.isLive).count
        let total = activities.count
        if live == 0 {
            return "\(total) activities coming soon"
        }
        return "\(live) of \(total) activities available"
    }

    // MARK: - Activity Rows

    private var activityRows: some View {
        VStack(spacing: BM.gridGap) {
            ForEach(activities) { activity in
                ActivityRow(activity: activity)
                    .onTapGesture {
                        guard activity.isLive else { return }
                        // Activity runner will be wired up in slice 2
                    }
            }
        }
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}

// MARK: - Activity Row

private struct ActivityRow: View {
    let activity: Activity

    var body: some View {
        HStack(spacing: 12) {
            // Initials square
            RoundedRectangle(cornerRadius: 12)
                .fill(activity.tintColor)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(activity.initials)
                        .font(.baloo2(16))
                        .foregroundStyle(.white)
                }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 7) {
                    Text(activity.name)
                        .font(.baloo2(14.5))
                        .foregroundStyle(Color.bmNavy)

                    if activity.showNewBadge {
                        badge("NEW", fill: Color.bmYellow, textColor: Color.bmNavy)
                    }

                    if activity.isStub {
                        badge("SOON", fill: Color.bmNavy09, textColor: Color.bmNavy.opacity(0.60))
                    }
                }

                Text(activity.desc)
                    .font(.nunito(12.5))
                    .foregroundStyle(Color.bmNavy62)
                    .lineLimit(1)
            }

            Spacer()

            if activity.isLive {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
            }
        }
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: BM.cardRadius)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: BM.cardRadius)
                        .stroke(Color.bmNavy09, lineWidth: BM.cardBorderWidth)
                }
                .bmCardShadow()
        }
    }

    private func badge(_ text: String, fill: Color, textColor: Color) -> some View {
        Text(text)
            .font(.nunito(8.5, weight: .extraBold))
            .tracking(0.4)
            .foregroundStyle(textColor)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Capsule().fill(fill))
    }
}

#Preview {
    NavigationStack {
        ActivityListView(umbrellaKey: "words-and-concepts", path: .constant(NavigationPath()))
            .environment(APIClient())
    }
}
