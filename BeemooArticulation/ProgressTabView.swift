import SwiftUI

struct ProgressTabView: View {
    @Environment(APIClient.self) private var apiClient
    @Environment(TrialLogger.self) private var trialLogger

    private let headerGradient = LinearGradient(
        colors: [Color(hex: "FFF3CE"), Color.bmCream],
        startPoint: .top,
        endPoint: .bottom
    )

    private let concepts = ["ONE", "MANY", "NONE", "MORE", "LESS", "MOST", "LEAST", "ALL", "SOME"]

    private var records: [TrialRecord] { trialLogger.records() }

    private var overallAccuracy: Double {
        let firstTries = records.filter(\.firstTry)
        guard !records.isEmpty else { return 0 }
        // Count unique screens where firstTry was true
        let total = Set(records.map(\.screenId)).count
        let correct = Set(firstTries.map(\.screenId)).count
        guard total > 0 else { return 0 }
        return Double(correct) / Double(total)
    }

    private func accuracy(for concept: String) -> (correct: Int, total: Int) {
        let conceptRecords = records.filter { $0.concept.uppercased() == concept }
        let uniqueScreens = Set(conceptRecords.map(\.screenId))
        let total = uniqueScreens.count
        let correct = uniqueScreens.filter { screenId in
            conceptRecords.first { $0.screenId == screenId }?.firstTry == true
        }.count
        return (correct, total)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                accuracyCard
                    .padding(.top, 16)
                byConceptCard
                    .padding(.top, BM.gridGap)
                Spacer(minLength: 18)
            }
        }
        .background {
            VStack(spacing: 0) {
                headerGradient.frame(height: 160)
                Color.bmCream
            }
            .ignoresSafeArea()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Progress")
                .font(.baloo2(22))
                .foregroundStyle(Color.bmNavy)
            Text("\(apiClient.childName) · this week")
                .font(.nunito(12))
                .foregroundStyle(Color.bmNavy60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 46)
        .padding(.bottom, 14)
    }

    // MARK: - Accuracy Card

    private var accuracyCard: some View {
        VStack(spacing: 10) {
            HStack(spacing: 16) {
                // Conic ring
                ZStack {
                    Circle()
                        .stroke(Color.bmNavy09, lineWidth: 6)
                        .frame(width: 56, height: 56)
                    Circle()
                        .trim(from: 0, to: overallAccuracy)
                        .stroke(Color.bmBlue, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))
                    Text("\(Int(overallAccuracy * 100))%")
                        .font(.baloo2(16))
                        .foregroundStyle(Color.bmNavy)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("HOW MUCH accuracy")
                        .font(.baloo2(14))
                        .foregroundStyle(Color.bmNavy)
                    Text("\(records.count) trials this week")
                        .font(.nunito(11.5))
                        .foregroundStyle(Color.bmNavy62)
                }

                Spacer()
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
        .padding(.horizontal, BM.sectionPadH)
    }

    // MARK: - By Concept Card

    private var byConceptCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("By concept")
                .font(.baloo2(14))
                .foregroundStyle(Color.bmNavy)
            Text("First-try accuracy on receptive trials")
                .font(.nunito(10.5))
                .foregroundStyle(Color.bmNavy50)

            ForEach(concepts, id: \.self) { concept in
                conceptRow(concept)
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
        .padding(.horizontal, BM.sectionPadH)
    }

    private func conceptRow(_ concept: String) -> some View {
        let stats = accuracy(for: concept)
        let pct = stats.total > 0 ? Double(stats.correct) / Double(stats.total) : 0
        let hasTrial = stats.total > 0

        return HStack(spacing: 10) {
            Text(concept)
                .font(.nunito(12, weight: .bold))
                .foregroundStyle(Color.bmNavy)
                .frame(width: 50, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.bmNavy09)
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(hasTrial ? Color.bmBlue : Color.bmNavy09)
                        .frame(width: max(geo.size.width * pct, hasTrial ? 4 : 0), height: 8)
                }
            }
            .frame(height: 8)

            Text(stats.total > 0 ? "\(Int(pct * 100))%" : "—")
                .font(.nunito(11, weight: .bold))
                .foregroundStyle(hasTrial ? Color.bmNavy : Color.bmNavy50)
                .frame(width: 36, alignment: .trailing)
        }
        .frame(height: 24)
    }
}
