import SwiftUI

enum BMTab: Int, CaseIterable {
    case home, progress, rewards, parents

    var label: String {
        switch self {
        case .home: "Home"
        case .progress: "Progress"
        case .rewards: "Rewards"
        case .parents: "Parents"
        }
    }

    var icon: String {
        switch self {
        case .home: "house.fill"
        case .progress: "chart.bar.fill"
        case .rewards: "star.fill"
        case .parents: "person.fill"
        }
    }
}

struct BMTabBar: View {
    @Binding var selected: BMTab

    var body: some View {
        VStack(spacing: 0) {
            // Hairline top border
            Rectangle()
                .fill(Color.bmNavy09)
                .frame(height: 0.5)

            HStack(spacing: 0) {
                ForEach(BMTab.allCases, id: \.self) { tab in
                    tabButton(tab)
                }
            }
            .frame(height: 56)
            .background(Color.bmCream)
        }
    }

    private func tabButton(_ tab: BMTab) -> some View {
        let isSelected = selected == tab
        let color = isSelected ? Color.bmNavy : Color.bmNavy50

        return Button {
            selected = tab
        } label: {
            VStack(spacing: 2) {
                ZStack(alignment: .top) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 24))
                        .foregroundStyle(color)

                    // Yellow selected dot
                    if isSelected {
                        Circle()
                            .fill(Color.bmYellow)
                            .frame(width: 4, height: 4)
                            .offset(y: -3)
                    }
                }

                Text(tab.label)
                    .font(.nunito(10, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
