import SwiftUI

struct RewardsTabView: View {
    @Environment(APIClient.self) private var apiClient
    @State private var bobOffset: CGFloat = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header

                // Daily challenge card
                dailyChallengeCard

                // Badge grid
                badgeGrid
            }
        }
        .background(Color.bmCream)
        .onAppear {
            withAnimation(.bmBob) { bobOffset = -8 }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Rewards")
                .font(.baloo2(22))
                .foregroundStyle(Color.bmNavy)
            Text("\(apiClient.childName)'s badges")
                .font(.nunito(12))
                .foregroundStyle(Color.bmNavy60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 16)
    }

    private var dailyChallengeCard: some View {
        HStack(spacing: 12) {
            Image("star")
                .resizable()
                .scaledToFit()
                .frame(width: 66, height: 66)
                .offset(y: bobOffset)

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Challenge")
                    .font(.baloo2(13.5))
                    .foregroundStyle(Color.bmNavy)
                Text("Complete 5 activities to earn your badge.")
                    .font(.nunito(11))
                    .foregroundStyle(Color.bmNavy60)
                Text("\(apiClient.activitiesCompletedToday) / 5")
                    .font(.baloo2(13))
                    .foregroundStyle(Color.bmOrange)
            }
            Spacer()
        }
        .padding(15)
        .background {
            RoundedRectangle(cornerRadius: BM.cardRadius)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: BM.cardRadius)
                        .stroke(Color.bmNavy09, lineWidth: BM.cardBorderWidth)
                }
                .bmCardShadow()
        }
        .padding(.horizontal, BM.sectionPadH)
    }

    private var badgeGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: BM.gridGap),
            GridItem(.flexible(), spacing: BM.gridGap),
            GridItem(.flexible(), spacing: BM.gridGap)
        ]
        return LazyVGrid(columns: columns, spacing: BM.gridGap) {
            ForEach(0..<6) { i in
                VStack(spacing: 6) {
                    Circle()
                        .fill(Color.bmNavy09)
                        .frame(width: 64, height: 64)
                        .overlay {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color.bmNavy50)
                        }
                    Text("Badge \(i + 1)")
                        .font(.nunito(10, weight: .bold))
                        .foregroundStyle(Color.bmNavy50)
                }
            }
        }
        .padding(.horizontal, BM.sectionPadH)
    }
}
