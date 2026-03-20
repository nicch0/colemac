import SwiftUI

struct KeyboardView: View {
    let currentLevel: Level

    private static let rowCount: CGFloat = 5
    private static let maxCols: CGFloat = 13

    // Colemak layout rows
    private static let rows: [[KeyDef]] = [
        [.key("`"), .key("1"), .key("2"), .key("3"), .key("4"), .key("5"),
         .key("6"), .key("7"), .key("8"), .key("9"), .key("0"), .key("-"), .key("=")],
        [.key("q"), .key("w"), .key("f"), .key("p"), .key("g"),
         .key("j"), .key("l"), .key("u"), .key("y"), .key(";"),
         .key("["), .key("]"), .key("\\")],
        [.key("a"), .key("r"), .key("s"), .key("t"), .key("d"),
         .key("h"), .key("n"), .key("e"), .key("i"), .key("o"), .key("'")],
        [.key("z"), .key("x"), .key("c"), .key("v"), .key("b"),
         .key("k"), .key("m"), .key(","), .key("."), .key("/")],
        [.space],
    ]

    // Which level introduced each key
    private static let keyLevel: [Character: Int] = {
        var map: [Character: Int] = [:]
        for level in Level.all {
            for c in level.newKeys {
                map[c] = level.id
            }
        }
        return map
    }()

    var body: some View {
        GeometryReader { geo in
            let gap: CGFloat = 4
            let padding: CGFloat = 8
            let totalGapsV = gap * (Self.rowCount - 1) + padding * 2
            let totalGapsH = gap * (Self.maxCols - 1) + padding * 2
            let keyH = (geo.size.height - totalGapsV) / Self.rowCount
            let keyW = (geo.size.width - totalGapsH) / Self.maxCols
            let keySize = min(keyH, keyW)
            let fontSize = keySize * 0.4

            VStack(spacing: gap) {
                ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: gap) {
                        ForEach(Array(row.enumerated()), id: \.offset) { _, keyDef in
                            keyView(keyDef, keySize: keySize, fontSize: fontSize)
                        }
                    }
                }
            }
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func keyView(_ keyDef: KeyDef, keySize: CGFloat, fontSize: CGFloat) -> some View {
        switch keyDef {
        case .key(let label):
            let char = label.first!
            let keyLvl = Self.keyLevel[char]
            let isUnlocked = keyLvl != nil && keyLvl! <= currentLevel.id
            let color = keyColor(for: char)

            RoundedRectangle(cornerRadius: 4)
                .stroke(isUnlocked ? color : AppTheme.keyBorder, lineWidth: 1.5)
                .frame(width: keySize, height: keySize)
                .overlay {
                    if isUnlocked {
                        Text(label.uppercased())
                            .font(.system(size: fontSize, weight: .bold, design: .monospaced))
                            .foregroundColor(color)
                    }
                }

        case .space:
            RoundedRectangle(cornerRadius: 4)
                .stroke(AppTheme.keyBorder, lineWidth: 1.5)
                .frame(width: keySize * 6, height: keySize)
        }
    }

    private func keyColor(for char: Character) -> Color {
        guard let keyLvl = Self.keyLevel[char] else {
            return AppTheme.keyBorder
        }
        if keyLvl == currentLevel.id {
            return AppTheme.accentGreen
        } else if keyLvl == 1 {
            return AppTheme.keyOrange
        } else {
            return AppTheme.keyPurple
        }
    }

    private enum KeyDef {
        case key(String)
        case space
    }
}

#Preview("Level 1") {
    KeyboardView(currentLevel: Level.all[0])
        .frame(width: 700, height: 250)
        .background(AppTheme.background)
}

#Preview("Level 4") {
    KeyboardView(currentLevel: Level.all[3])
        .frame(width: 700, height: 250)
        .background(AppTheme.background)
}

#Preview("Master") {
    KeyboardView(currentLevel: Level.all[6])
        .frame(width: 700, height: 250)
        .background(AppTheme.background)
}
