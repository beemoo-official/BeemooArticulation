import SwiftUI

/// S Sound landing screen — "Let's Practice the S Sound!"
/// Offers three entry points: Guided Learning, Choose an Activity, Flashcard Practice.
struct SPracticeHomeView: View {
    let onDismiss: () -> Void

    @Environment(APIClient.self) private var apiClient
    @Environment(TrialLogger.self) private var trialLogger
    @Environment(RunnerSettings.self) private var runnerSettings
    @Environment(SProgressStore.self) private var progressStore

    private let levels: [(Int, String)] = [
        (1, "Make the S Sound"),
        (2, "Hear the S Sound"),
        (3, "Beginning S Words"),
        (4, "Final S Words"),
        (5, "Middle S Words"),
        (6, "Beginning S Sentences"),
        (7, "Final S Sentences"),
        (8, "Middle S Sentences"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Back button
                HStack {
                    BackButton(action: onDismiss)
                    Spacer()
                }

                // Title
                Text("Let's Practice the S Sound!")
                    .font(.baloo2(26))
                    .foregroundStyle(Color.bmNavy)

                // Guided Learning button
                guidedLearningCard

                // Choose an Activity
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose an Activity")
                        .font(.baloo2(18))
                        .foregroundStyle(Color.bmNavy)
                        .padding(.leading, 4)

                    levelGrid
                }

                // Flashcard Practice
                flashcardCard
            }
            .padding(.horizontal, BM.sectionPadH)
            .padding(.bottom, 30)
        }
        .background(Color.bmCream.ignoresSafeArea())
    }

    // MARK: - Guided Learning

    private var guidedLearningCard: some View {
        let currentLevel = progressStore.highestUnlockedLevel
        let levelName = levels.first { $0.0 == currentLevel }?.1 ?? "Level \(currentLevel)"

        return Button {
            launchLevel(currentLevel)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "graduationcap.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.bmConceptGreen))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Guided Learning")
                        .font(.baloo2(17))
                        .foregroundStyle(Color.bmNavy)
                    Text("Continue: \(levelName)")
                        .font(.nunito(13))
                        .foregroundStyle(Color.bmNavy62)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: BM.cardRadius)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: BM.cardRadius)
                            .stroke(Color.bmConceptGreen.opacity(0.3), lineWidth: 2)
                    )
                    .bmCardShadow()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Level Grid

    private var levelGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: BM.gridGap),
            GridItem(.flexible(), spacing: BM.gridGap),
        ], spacing: BM.gridGap) {
            ForEach(levels, id: \.0) { level, name in
                levelCard(level: level, name: name)
            }
        }
    }

    private func levelCard(level: Int, name: String) -> some View {
        let accuracy = progressStore.levelAccuracy[level]
        let isCurrent = level == progressStore.highestUnlockedLevel

        return Button {
            launchLevel(level)
        } label: {
            HStack(spacing: 10) {
                // Level number badge
                Text("\(level)")
                    .font(.baloo2(18))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle().fill(isCurrent ? Color.bmConceptGreen : Color.bmBlue)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.nunito(13, weight: .bold))
                        .foregroundStyle(Color.bmNavy)
                        .lineLimit(1)

                    if let acc = accuracy {
                        Text("\(Int(acc * 100))% accuracy")
                            .font(.nunito(11))
                            .foregroundStyle(Color.bmConceptGreen)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: BM.cardRadius)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: BM.cardRadius)
                            .stroke(isCurrent ? Color.bmConceptGreen.opacity(0.3) : Color.bmNavy09, lineWidth: BM.cardBorderWidth)
                    )
                    .bmCardShadow()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Flashcard Practice

    private var flashcardCard: some View {
        Button {
            launchFlashcards()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "rectangle.stack.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Circle().fill(Color.bmBlue))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Flashcard Practice")
                        .font(.baloo2(17))
                        .foregroundStyle(Color.bmNavy)
                    Text("Practice all S words at your own pace")
                        .font(.nunito(13))
                        .foregroundStyle(Color.bmNavy62)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: BM.cardRadius)
                    .fill(.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: BM.cardRadius)
                            .stroke(Color.bmBlue.opacity(0.3), lineWidth: 2)
                    )
                    .bmCardShadow()
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Launch

    private func launchLevel(_ level: Int) {
        let activityId = "s-sound-level-\(level)"
        let config = SeedData.loadActivityConfig(activityId)
        let runner = ActivityRunnerView(config: config) { [self] in
            // Compute accuracy from trials logged during this activity
            let trials = trialLogger.records().filter { $0.activityId == activityId }
            let firstAttemptCorrect = trials.filter { $0.firstAttemptOutcome == "correct" }.count
            let total = trials.count

            progressStore.recordLevelCompletion(
                level: level,
                correctFirstAttempts: firstAttemptCorrect,
                totalTrials: total,
                trialThreshold: runnerSettings.trialThreshold,
                accuracyThreshold: runnerSettings.accuracyThreshold
            )

            LandscapePresenter.dismiss()
        }
        .environment(apiClient)
        .environment(trialLogger)
        .environment(runnerSettings)
        .environment(progressStore)
        LandscapePresenter.present(runner)
    }

    private func launchFlashcards() {
        let config = SeedData.loadActivityConfig("s-sound-flashcards")
        let runner = ActivityRunnerView(config: config) {
            LandscapePresenter.dismiss()
        }
        .environment(apiClient)
        .environment(trialLogger)
        .environment(runnerSettings)
        .environment(progressStore)
        LandscapePresenter.present(runner)
    }
}
