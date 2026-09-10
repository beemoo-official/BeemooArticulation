import SwiftUI

// MARK: - Colour tokens

extension Color {
    static let bmNavy = Color(red: 22/255, green: 48/255, blue: 91/255)
    static let bmNavy62 = bmNavy.opacity(0.62)
    static let bmNavy50 = bmNavy.opacity(0.50)
    static let bmNavy09 = bmNavy.opacity(0.09)

    static let bmConceptGreen = Color(red: 31/255, green: 138/255, blue: 72/255)
    static let bmBlue = Color(red: 30/255, green: 136/255, blue: 229/255)
    static let bmBlueDark = Color(red: 15/255, green: 111/255, blue: 196/255)
    static let bmWCBlue = Color(red: 30/255, green: 95/255, blue: 168/255)

    static let bmYellow = Color(red: 255/255, green: 209/255, blue: 0/255)
    static let bmYellowHover = Color(red: 255/255, green: 224/255, blue: 102/255)
    static let bmOrange = Color(red: 242/255, green: 128/255, blue: 31/255)

    static let bmCream = Color(red: 255/255, green: 253/255, blue: 246/255)
    static let bmIce = Color(red: 244/255, green: 248/255, blue: 254/255)

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        self.init(
            red: Double((rgb >> 16) & 0xFF) / 255,
            green: Double((rgb >> 8) & 0xFF) / 255,
            blue: Double(rgb & 0xFF) / 255
        )
    }
}

// MARK: - Typography

extension Font {
    static func baloo2(_ size: CGFloat) -> Font {
        .custom("Baloo2-ExtraBold", size: size)
    }

    static func nunito(_ size: CGFloat, weight: NunitoWeight = .semiBold) -> Font {
        .custom(weight.fontName, size: size)
    }

    enum NunitoWeight {
        case semiBold, bold, extraBold

        var fontName: String {
            switch self {
            case .semiBold: "Nunito-SemiBold"
            case .bold: "Nunito-Bold"
            case .extraBold: "Nunito-ExtraBold"
            }
        }
    }
}

// MARK: - Geometry

enum BM {
    static let cardRadius: CGFloat = 20
    static let innerCardRadius: CGFloat = 18
    static let pillRadius: CGFloat = 999
    static let sheetTopRadius: CGFloat = 26

    static let cardBorderWidth: CGFloat = 1.5

    static let gridGap: CGFloat = 11
    static let sectionPadH: CGFloat = 16
    static let hitTarget: CGFloat = 44

    static let transitionDuration: Double = 0.26
}

// MARK: - Shadows

extension View {
    func bmCardShadow() -> some View {
        shadow(color: Color(red: 22/255, green: 48/255, blue: 91/255).opacity(0.05), radius: 7, x: 0, y: 4)
    }

    func bmRaisedShadow() -> some View {
        shadow(color: .black.opacity(0.12), radius: 9, x: 0, y: 6)
    }

    func bmFloatingControlShadow() -> some View {
        shadow(color: .black.opacity(0.10), radius: 5, x: 0, y: 3)
    }

    func bmBackButtonShadow() -> some View {
        shadow(color: Color(red: 22/255, green: 48/255, blue: 91/255).opacity(0.12), radius: 4.5, x: 0, y: 3)
    }
}

// MARK: - Animations

extension Animation {
    static let bmFloat = Animation.easeInOut(duration: 5.5).repeatForever(autoreverses: true)
    static let bmBob = Animation.easeInOut(duration: 3.4).repeatForever(autoreverses: true)
}
