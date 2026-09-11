import SwiftUI

struct TipsView: View {
    @Environment(\.dismiss) private var dismiss
    private let tips: [(category: String, title: String, body: String)] = [
        ("AT HOME", "Follow your child's lead",
         "Let your child choose the activity or toy. Then use the target words naturally — \"You picked one block! Can you find many blocks?\""),
        ("PROMPTING", "Give wait time",
         "After asking a question, wait 5–10 seconds before giving a hint. Children need processing time, and jumping in too quickly teaches them to wait for the answer."),
        ("AT HOME", "Use real objects",
         "Practice quantity words during meals, bath time, and play. \"You have many bubbles! Now there are none.\" Real-world practice transfers faster than screen practice."),
        ("PROMPTING", "Model, don't correct",
         "If your child says \"I want that ones,\" respond with the correct form: \"You want that one? Here you go!\" Recasting is more effective than asking them to repeat it."),
        ("AT HOME", "Read together daily",
         "Point to pictures and use target words. \"The bear has all the honey. Now he has none!\" Books are a natural context for every concept in this app."),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: BM.gridGap) {
                    ForEach(Array(tips.enumerated()), id: \.offset) { _, tip in
                        tipCard(tip)
                    }
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
                Text("Tips for Parents")
                    .font(.baloo2(21))
                    .foregroundStyle(Color.bmNavy)
            }
            Spacer()
        }
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func tipCard(_ tip: (category: String, title: String, body: String)) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(tip.category)
                .font(.nunito(8.5, weight: .extraBold))
                .tracking(0.4)
                .foregroundStyle(Color.bmNavy50)

            Text(tip.title)
                .font(.baloo2(14.5))
                .foregroundStyle(Color.bmNavy)

            Text(tip.body)
                .font(.nunito(12.5))
                .foregroundStyle(Color.bmNavy62)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
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
