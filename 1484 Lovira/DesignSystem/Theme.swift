import SwiftUI

enum Theme {
    static let background = Color(hex: 0x131313)
    static let backgroundSecondary = Color(hex: 0x1A1A1A)
    static let surface = Color(hex: 0x1F1F1F)
    static let surfaceHigh = Color(hex: 0x282828)
    static let stroke = Color(hex: 0x303030)

    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xA4A4A4)
    static let textTertiary = Color(hex: 0x616162)

    static let pink = Color(hex: 0xF97187)
    static let pinkDark = Color(hex: 0xE75275)
    static let pinkSoft = Color(hex: 0xF97187).opacity(0.41)
    static let pinkBackground = Color(hex: 0x2D1A1F)
    static let violet = Color(hex: 0x9880FF)
    static let blue = Color(hex: 0x4346E6)
    static let gold = Color(hex: 0xFCD227)
    static let error = Color(hex: 0xFF356E)
    static let online = Color(hex: 0x3DDC84)

    static let ctaGradient = LinearGradient(
        colors: [Color(hex: 0xFF7B91), Color(hex: 0xE65073)],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let premiumGradient = LinearGradient(
        colors: [Color(hex: 0xFC768A), Color(hex: 0xA05EB8), Color(hex: 0x4346E6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let photoFade = LinearGradient(
        colors: [.clear, Color(hex: 0x131313).opacity(0.7), Color(hex: 0x131313)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardFade = LinearGradient(
        colors: [.clear, .black.opacity(0.35), .black.opacity(0.85)],
        startPoint: .center,
        endPoint: .bottom
    )

    static let cornerRadius: CGFloat = 20
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}

enum PoppinsWeight: String {
    case regular = "Poppins-Regular"
    case medium = "Poppins-Medium"
    case semibold = "Poppins-SemiBold"
    case bold = "Poppins-Bold"
}

extension Font {
    static func poppins(
        _ size: CGFloat,
        _ weight: PoppinsWeight = .regular,
        relativeTo style: Font.TextStyle = .body
    ) -> Font {
        .custom(weight.rawValue, size: size, relativeTo: style)
    }

    static let appTitle = poppins(28, .bold, relativeTo: .largeTitle)
    static let appH2 = poppins(22, .semibold, relativeTo: .title2)
    static let appH3 = poppins(18, .semibold, relativeTo: .headline)
    static let appBody = poppins(16, .regular, relativeTo: .body)
    static let appBodyMedium = poppins(16, .medium, relativeTo: .body)
    static let appCallout = poppins(14, .medium, relativeTo: .callout)
    static let appSubheadline = poppins(14, .regular, relativeTo: .subheadline)
    static let appCaption = poppins(12, .regular, relativeTo: .caption)
    static let appCaptionBold = poppins(12, .semibold, relativeTo: .caption)
}
