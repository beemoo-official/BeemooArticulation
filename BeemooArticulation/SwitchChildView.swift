import SwiftUI

struct SwitchChildView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(APIClient.self) private var apiClient

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: BM.gridGap) {
                    childRow(name: apiClient.childName, age: 5, isSelected: true)
                    addChildRow
                }
                .padding(.horizontal, BM.sectionPadH)
                .padding(.top, 12)
            }
        }
        .background(Color.bmCream)
        .toolbar(.hidden)
    }

    private var header: some View {
        HStack {
            BackButton { dismiss() }
            Text("Switch Child")
                .font(.baloo2(21))
                .foregroundStyle(Color.bmNavy)
            Spacer()
        }
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func childRow(name: String, age: Int, isSelected: Bool) -> some View {
        HStack(spacing: 14) {
            Image("avatar")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.baloo2(14.5))
                    .foregroundStyle(Color.bmNavy)
                Text("Age \(age) · 0 sessions")
                    .font(.nunito(12))
                    .foregroundStyle(Color.bmNavy62)
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.bmBlue)
            }
        }
        .padding(13)
        .background {
            RoundedRectangle(cornerRadius: BM.cardRadius)
                .fill(.white)
                .overlay {
                    RoundedRectangle(cornerRadius: BM.cardRadius)
                        .stroke(isSelected ? Color.bmBlue : Color.bmNavy09, lineWidth: isSelected ? 2 : BM.cardBorderWidth)
                }
                .bmCardShadow()
        }
    }

    private var addChildRow: some View {
        HStack(spacing: 14) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 22))
                .foregroundStyle(Color.bmBlue)

            Text("Add child")
                .font(.baloo2(14.5))
                .foregroundStyle(Color.bmBlue)

            Spacer()
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
}
