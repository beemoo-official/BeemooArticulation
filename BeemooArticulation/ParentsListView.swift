import SwiftUI

struct ParentsListView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header

                VStack(spacing: BM.gridGap) {
                    parentRow("Tips for Parents", icon: "lightbulb.fill", route: .tips)
                    parentRow("Settings", icon: "gearshape.fill", route: .settings)
                    parentRow("Switch Child", icon: "person.2.fill", route: .switchChild)
                    parentRow("Subscription", icon: "creditcard.fill", route: .subscription)
                }
                .padding(.horizontal, BM.sectionPadH)
                .padding(.top, 12)
            }
        }
        .background(Color.bmCream)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Parents")
                .font(.baloo2(22))
                .foregroundStyle(Color.bmNavy)
            Text("Account and settings")
                .font(.nunito(12))
                .foregroundStyle(Color.bmNavy60)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, BM.sectionPadH)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    private func parentRow(_ title: String, icon: String, route: ParentsRoute) -> some View {
        NavigationLink(value: route) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(Color.bmNavy)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.bmNavy09))

                Text(title)
                    .font(.baloo2(14.5))
                    .foregroundStyle(Color.bmNavy)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.bmNavy50)
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
        .buttonStyle(.plain)
    }
}
