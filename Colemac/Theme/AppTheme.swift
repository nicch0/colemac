import SwiftUI

enum AppTheme {
    static let background = Color(red: 0.118, green: 0.118, blue: 0.118) // #1e1e1e
    static let surfaceBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    static let untypedText = Color.gray.opacity(0.5)
    static let correctText = Color.white
    static let incorrectText = Color(red: 0.9, green: 0.3, blue: 0.3)
    static let cursorColor = Color.yellow
    static let accentGreen = Color(red: 0.4, green: 0.8, blue: 0.4)
    static let subtleText = Color.gray.opacity(0.6)
    static let keyBorder = Color.purple.opacity(0.4)
    static let keyOrange = Color(red: 0.9, green: 0.65, blue: 0.2)
    static let keyPurple = Color(red: 0.7, green: 0.5, blue: 0.85)

    static let monoFont = Font.system(size: 20, design: .monospaced)
    static let monoFontSmall = Font.system(size: 14, design: .monospaced)
    static let monoFontLarge = Font.system(size: 24, design: .monospaced)

    static let pointerCursor = HoverModifier()

    struct HoverModifier: ViewModifier {
        func body(content: Content) -> some View {
            content.onHover { hovering in
                if hovering {
                    NSCursor.pointingHand.push()
                } else {
                    NSCursor.pop()
                }
            }
        }
    }
}
