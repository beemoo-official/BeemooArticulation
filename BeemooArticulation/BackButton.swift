import SwiftUI

struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(.white)
                .frame(width: BM.hitTarget, height: BM.hitTarget)
                .bmBackButtonShadow()
                .overlay {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.bmNavy)
                }
        }
    }
}
