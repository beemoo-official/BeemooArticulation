import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(APIClient.self) private var apiClient
    @Environment(RunnerSettings.self) private var settings

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: 20) {
                    childSection
                    activitySection
                    audioSection
                    accountSection
                }
                .padding(.horizontal, BM.sectionPadH)
                .padding(.top, 12)
                .padding(.bottom, 24)
            }
        }
        .background(Color.bmCream)
        .toolbar(.hidden)
    }

    private var header: some View {
        HStack {
            BackButton { dismiss() }
            VStack(alignment: .leading, spacing: 2) {
                Text("Settings")
                    .font(.baloo2(21))
                    .foregroundStyle(Color.bmNavy)
            }
            Spacer()
        }
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Child

    private var childSection: some View {
        settingsGroup("Child") {
            settingsRow("Name", value: apiClient.childName)
        }
    }

    // MARK: - Activity (these drive RunnerSettings)

    private var activitySection: some View {
        @Bindable var s = settings
        return settingsGroup("Activity") {
            VStack(spacing: 0) {
                Text("Wrong-answer response")
                    .font(.nunito(12, weight: .bold))
                    .foregroundStyle(Color.bmNavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                Picker("Wrong answer", selection: $s.wrongAnswerResponse) {
                    Text("Retry same screen").tag(RunnerSettings.WrongAnswerResponse.retrySameScreen)
                    Text("Advance anyway").tag(RunnerSettings.WrongAnswerResponse.advanceAnyway)
                    Text("Re-teach then retry").tag(RunnerSettings.WrongAnswerResponse.reTeachThenRetry)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 14)

                Text("Advance gating")
                    .font(.nunito(12, weight: .bold))
                    .foregroundStyle(Color.bmNavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 8)

                Picker("Advance", selection: $s.advanceGating) {
                    Text("Adult taps").tag(RunnerSettings.AdvanceGating.adultTaps)
                    Text("Auto-advance").tag(RunnerSettings.AdvanceGating.autoAdvance)
                }
                .pickerStyle(.segmented)
            }
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        @Bindable var s = settings
        return settingsGroup("Audio") {
            Toggle("Narration", isOn: $s.narrationEnabled)
                .font(.nunito(12, weight: .bold))
                .foregroundStyle(Color.bmNavy)
                .tint(Color.bmBlue)
        }
    }

    // MARK: - Account

    private var accountSection: some View {
        settingsGroup("Account") {
            settingsRow("Subscription", value: "Free")
            settingsRow("Sign out", value: "")
        }
    }

    // MARK: - Helpers

    private func settingsGroup<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.nunito(10, weight: .extraBold))
                .tracking(0.4)
                .foregroundStyle(Color.bmNavy50)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
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
    }

    private func settingsRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.nunito(12, weight: .bold))
                .foregroundStyle(Color.bmNavy)
            Spacer()
            Text(value)
                .font(.nunito(12))
                .foregroundStyle(Color.bmNavy62)
        }
        .padding(.vertical, 4)
    }
}
