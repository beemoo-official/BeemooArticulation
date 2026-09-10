import SwiftUI

struct HomeView: View {
    @Environment(APIClient.self) private var apiClient
    @Binding var path: NavigationPath
    @State private var floatOffset: CGFloat = 0
    @State private var floatRotation: Double = 0
    @State private var bobOffset: CGFloat = 0

    private let heroGradient = LinearGradient(
        colors: [Color(hex: "FFF6DA"), Color(hex: "FFEFB8"), Color(hex: "FFE07A")],
        startPoint: .top,
        endPoint: .bottom
    )

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroBlock
                umbrellaGrid
                    .padding(.top, 0)
                progressCard
                    .padding(.top, BM.gridGap)
                dailyChallengeCard
                    .padding(.top, BM.gridGap)
                subscriptionBanner
                    .padding(.top, BM.gridGap)
                Spacer(minLength: 18)
            }
        }
        .background(Color.bmCream)
        .onAppear {
            withAnimation(.bmFloat) {
                floatOffset = -14
                floatRotation = 2
            }
            withAnimation(.bmBob) {
                bobOffset = -8
            }
        }
    }

    // MARK: - Hero Block

    private var heroBlock: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                VStack(spacing: 0) {
                    headerRow
                        .padding(.top, 44)
                        .padding(.horizontal, 18)
                    brandBlock
                        .padding(.top, 10)
                }
                .background(heroGradient)
            }

            // Cream cap at bottom
            RoundedRectangle(cornerRadius: BM.sheetTopRadius)
                .fill(Color.bmCream)
                .frame(height: 52)
                .offset(y: 26)
        }
        .clipped()
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: BM.gridGap) {
            // Child avatar
            Circle()
                .fill(Color.bmBlue.opacity(0.2))
                .frame(width: 46, height: 46)
                .overlay {
                    Text(String(apiClient.childName.prefix(1)))
                        .font(.baloo2(18))
                        .foregroundStyle(Color.bmNavy)
                }
                .overlay {
                    Circle().stroke(.white, lineWidth: 3)
                }
                .shadow(color: .black.opacity(0.14), radius: 5, x: 0, y: 3)

            // Name block
            VStack(alignment: .leading, spacing: 1) {
                Text("Hi, \(apiClient.childName)!")
                    .font(.baloo2(17))
                    .foregroundStyle(Color.bmNavy)
                Text("Let's practice!")
                    .font(.nunito(12.5))
                    .foregroundStyle(Color.bmNavy62)
            }

            Spacer()

            // Switch Child pill
            Button(action: {}) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.bmNavy)
                        .frame(width: 15, height: 15)
                    Text("Switch Child")
                        .font(.nunito(12.5, weight: .extraBold))
                        .foregroundStyle(Color.bmNavy)
                }
                .padding(.horizontal, 14)
                .frame(height: BM.hitTarget)
                .background(Capsule().fill(.white))
            }

            // Settings
            Button(action: {}) {
                Circle()
                    .fill(.white)
                    .frame(width: BM.hitTarget, height: BM.hitTarget)
                    .overlay {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.bmNavy)
                    }
            }
        }
    }

    // MARK: - Brand Block

    private var brandBlock: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 8) {
                // Logo placeholder
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.5))
                    .frame(width: 192, height: 60)
                    .overlay {
                        Text("BeeMoo")
                            .font(.baloo2(28))
                            .foregroundStyle(Color.bmNavy)
                    }
                    .shadow(color: .black.opacity(0.13), radius: 4, x: 0, y: 4)

                // Tagline
                Text("Speech & Language Practice\nMade Simple. Made Fun.")
                    .font(.nunito(13, weight: .extraBold))
                    .foregroundStyle(Color.bmNavy)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 190)

                Spacer(minLength: 20)
            }
            .frame(minHeight: 214)
            .frame(maxWidth: .infinity)

            // BeeMoo character placeholder
            VStack(spacing: 0) {
                Circle()
                    .fill(Color.bmYellow.opacity(0.3))
                    .frame(width: 168, height: 168)
                    .overlay {
                        Text("🐝")
                            .font(.system(size: 70))
                    }
                    .offset(y: floatOffset)
                    .rotationEffect(.degrees(floatRotation - 2))

                // Speech bubble
                speechBubble
                    .padding(.top, -20)
            }
            .offset(x: -30, y: 14)
            .padding(.trailing, -30)
        }
        .padding(.horizontal, 18)
    }

    private var speechBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Hi! I'm BeeMoo!")
                .font(.baloo2(13.5))
                .foregroundStyle(Color.bmNavy)
            Text("Tap a category below to start practicing!")
                .font(.nunito(12.5))
                .foregroundStyle(Color.bmNavy.opacity(0.78))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(width: 214, alignment: .leading)
        .background {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 18)
                    .fill(.white)
                // Tail
                Rectangle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .rotationEffect(.degrees(45))
                    .offset(x: -7, y: -20)
            }
        }
    }

    // MARK: - Umbrella Grid

    private var umbrellaGrid: some View {
        let columns = [
            GridItem(.flexible(), spacing: BM.gridGap),
            GridItem(.flexible(), spacing: BM.gridGap)
        ]

        return LazyVGrid(columns: columns, spacing: BM.gridGap) {
            ForEach(apiClient.catalog.umbrellas) { umbrella in
                UmbrellaCard(umbrella: umbrella)
                    .onTapGesture {
                        path.append(Route.umbrella(key: umbrella.key))
                    }
            }
        }
        .padding(.horizontal, BM.sectionPadH)
        .padding(.bottom, 18)
    }

    // MARK: - Progress Card

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Progress")
                    .font(.baloo2(13.5))
                    .foregroundStyle(Color.bmNavy)
                Spacer()
                Button(action: {}) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.bmNavy50)
                }
            }

            HStack(spacing: 14) {
                // Progress ring
                ZStack {
                    Circle()
                        .stroke(Color.bmNavy09, lineWidth: 6)
                        .frame(width: 52, height: 52)
                    Circle()
                        .trim(from: 0, to: 0)
                        .stroke(Color.bmBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 0) {
                        Text("0/5")
                            .font(.baloo2(15))
                            .foregroundStyle(Color.bmNavy)
                        Text("Activities\nCompleted")
                            .font(.nunito(6.5, weight: .bold))
                            .foregroundStyle(Color.bmNavy)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(width: 64, height: 64)

                Text("Complete activities to track your daily progress!")
                    .font(.nunito(11))
                    .foregroundStyle(Color.bmNavy62)
            }
        }
        .padding(.horizontal, 13)
        .padding(.vertical, 13)
        .padding(.bottom, 1)
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

    // MARK: - Daily Challenge Card

    private var dailyChallengeCard: some View {
        HStack(spacing: 12) {
            // Star placeholder
            Text("⭐️")
                .font(.system(size: 44))
                .offset(y: bobOffset)

            VStack(alignment: .leading, spacing: 4) {
                Text("Daily Challenge")
                    .font(.baloo2(13.5))
                    .foregroundStyle(Color.bmNavy)
                Text("Complete 5 activities to earn your badge.")
                    .font(.nunito(11))
                    .foregroundStyle(Color.bmNavy.opacity(0.60))
                Text("0 / 5")
                    .font(.baloo2(13))
                    .foregroundStyle(Color.bmOrange)
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
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

    // MARK: - Subscription Banner

    private var subscriptionBanner: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("BeeMoo Everything")
                    .font(.baloo2(13))
                    .foregroundStyle(Color.bmYellow)
                Text("Unlock all activities and track your child's progress.")
                    .font(.nunito(11))
                    .foregroundStyle(.white.opacity(0.78))
            }

            Spacer()

            Button(action: {}) {
                Text("See plans")
                    .font(.nunito(12, weight: .extraBold))
                    .foregroundStyle(Color.bmNavy)
                    .padding(.horizontal, 16)
                    .frame(height: 40)
                    .background(Capsule().fill(Color.bmYellow))
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background {
            RoundedRectangle(cornerRadius: BM.cardRadius)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: "16305B"), Color(hex: "264A85")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .padding(.horizontal, BM.sectionPadH)
    }
}

// MARK: - Umbrella Card

private struct UmbrellaCard: View {
    let umbrella: Umbrella

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Icon placeholder
            RoundedRectangle(cornerRadius: 10)
                .fill(.white.opacity(0.5))
                .frame(width: 36, height: 36)
                .overlay {
                    Text(String(umbrella.title.prefix(1)))
                        .font(.baloo2(18))
                        .foregroundStyle(umbrella.inkColor)
                }

            Text(umbrella.title)
                .font(.baloo2(14.5))
                .foregroundStyle(umbrella.inkColor)

            Text(umbrella.desc)
                .font(.nunito(11))
                .foregroundStyle(Color.bmNavy62)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: BM.cardRadius)
                .fill(umbrella.tintColor)
        }
    }
}

#Preview {
    HomeView(path: .constant(NavigationPath()))
        .environment(APIClient())
}
