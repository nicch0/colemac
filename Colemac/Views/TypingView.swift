import SwiftUI

struct TypingView: View {
    @Bindable var engine: TypingEngine
    @FocusState private var isFocused: Bool
    @State private var cursorVisible = true

    private var isZen: Bool { engine.state.sessionMode.isZen }

    var body: some View {
        GeometryReader { geo in
            let scale = max(0.6, geo.size.width / 900)

            VStack(spacing: 0) {
                Spacer()

                if engine.state.isFinished {
                    resultsView(scale: scale)
                } else {
                    wordDisplay(scale: scale, containerWidth: geo.size.width)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24 * scale)
                }

                Spacer()

                if !isZen && !engine.state.isFinished {
                    statsBar
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .background(AppTheme.background)
        .onAppear {
            isFocused = true
            startCursorBlink()
        }
        .onKeyPress(.space) {
            engine.handleKeyPress(" ") ? .handled : .ignored
        }
        .onKeyPress(.delete) {
            engine.handleBackspace()
            return .handled
        }
        .onKeyPress(.escape) {
            if isZen {
                engine.finish()
            }
            return .handled
        }
        .onKeyPress(characters: .alphanumerics.union(.punctuationCharacters)) { press in
            let key = press.characters
            guard !key.isEmpty else { return .ignored }
            return engine.handleKeyPress(key) ? .handled : .ignored
        }
    }

    // MARK: - Results

    private func resultsView(scale: CGFloat) -> some View {
        VStack(spacing: 16 * scale) {
            Text(String(format: "%.0f", engine.state.wpm))
                .font(.system(size: 64 * scale, design: .monospaced))
                .foregroundColor(AppTheme.accentGreen)
            Text("wpm")
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)

            HStack(spacing: 32 * scale) {
                resultItem("accuracy", String(format: "%.0f%%", engine.state.accuracy), scale: scale)
                resultItem("words", "\(engine.state.wordsCompleted)", scale: scale)
                resultItem("time", formatDuration(engine.state.elapsedTime), scale: scale)
            }
            .padding(.top, 8 * scale)

            Button("again") {
                engine.reset()
                isFocused = true
            }
            .buttonStyle(.plain)
            .font(.system(size: 20 * scale, design: .monospaced))
            .foregroundColor(AppTheme.accentGreen)
            .padding(.top, 24 * scale)
        }
    }

    private func resultItem(_ label: String, _ value: String, scale: CGFloat) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.correctText)
            Text(label)
                .font(.system(size: 14 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)
        }
    }

    // MARK: - Word display

    private func wordDisplay(scale: CGFloat, containerWidth: CGFloat) -> some View {
        let fontSize = 24 * scale
        let charWidth = fontSize * 0.605
        let maxWidth = containerWidth - (48 * scale) // account for padding

        let lines = visibleLines(charWidth: charWidth, maxWidth: maxWidth)

        return VStack(alignment: .leading, spacing: 8 * scale) {
            ForEach(Array(lines.enumerated()), id: \.offset) { lineIndex, line in
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { wordOffset, wordInfo in
                        if wordOffset > 0 {
                            Text(" ")
                                .font(.system(size: fontSize, design: .monospaced))
                                .foregroundColor(AppTheme.untypedText)
                        }
                        wordView(wordIndex: wordInfo.index, word: wordInfo.word, fontSize: fontSize)
                    }
                }
            }
        }
    }

    private func wordView(wordIndex: Int, word: String, fontSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { charIndex, char in
                let color = charColor(wordIndex: wordIndex, charIndex: charIndex)
                let isCursor = wordIndex == engine.state.currentWordIndex && charIndex == engine.state.currentCharIndex

                ZStack(alignment: .leading) {
                    Text(String(char))
                        .font(.system(size: fontSize, design: .monospaced))
                        .foregroundColor(color)

                    if isCursor && cursorVisible {
                        Rectangle()
                            .fill(AppTheme.cursorColor)
                            .frame(width: 2, height: fontSize)
                            .offset(x: -1)
                    }
                }
            }
        }
    }

    private func charColor(wordIndex: Int, charIndex: Int) -> Color {
        guard wordIndex < engine.state.typedChars.count else { return AppTheme.untypedText }
        let typed = engine.state.typedChars[wordIndex]

        if charIndex < typed.count {
            switch typed[charIndex] {
            case .correct: return AppTheme.correctText
            case .incorrect: return AppTheme.incorrectText
            }
        }

        if wordIndex < engine.state.currentWordIndex {
            return AppTheme.correctText
        }

        return AppTheme.untypedText
    }

    // MARK: - Stats bar

    private var statsBar: some View {
        HStack(spacing: 32) {
            if let _ = engine.state.targetSeconds, engine.state.startTime != nil {
                statItem(label: "", value: formatDuration(engine.state.remainingTime))
            } else if case .words(let target) = engine.state.sessionMode {
                statItem(label: "/ \(target)", value: "\(engine.state.wordsCompleted)")
            }

            statItem(label: "wpm", value: String(format: "%.0f", engine.state.wpm))
            statItem(label: "acc", value: String(format: "%.0f%%", engine.state.accuracy))

            Spacer()

            Button("reset") {
                engine.reset()
                isFocused = true
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.subtleText)
            .font(AppTheme.monoFontSmall)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceBackground)
    }

    private func statItem(label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Text(value)
                .font(AppTheme.monoFont)
                .foregroundColor(AppTheme.accentGreen)
            Text(label)
                .font(AppTheme.monoFontSmall)
                .foregroundColor(AppTheme.subtleText)
        }
    }

    private func startCursorBlink() {
        Timer.scheduledTimer(withTimeInterval: 0.53, repeats: true) { _ in
            cursorVisible.toggle()
        }
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        let mins = total / 60
        let secs = total % 60
        return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)s"
    }

    // MARK: - Line splitting

    struct WordInfo {
        let index: Int
        let word: String
    }

    private func visibleLines(charWidth: CGFloat, maxWidth: CGFloat) -> [[WordInfo]] {
        let words = engine.state.words
        let currentWordIndex = engine.state.currentWordIndex

        // Build all lines from the start
        var allLines: [[WordInfo]] = []
        var currentLine: [WordInfo] = []
        var lineWidth: CGFloat = 0

        for i in 0..<words.count {
            let word = words[i]
            let wordWidth = CGFloat(word.count) * charWidth
            let spaceWidth = currentLine.isEmpty ? 0 : charWidth

            if lineWidth + spaceWidth + wordWidth > maxWidth && !currentLine.isEmpty {
                allLines.append(currentLine)
                currentLine = []
                lineWidth = 0
            }

            currentLine.append(WordInfo(index: i, word: word))
            lineWidth += spaceWidth + wordWidth

            // Stop building lines once we have enough ahead of cursor
            if allLines.count > 0 {
                let lastLineContainsCursor = allLines.last?.contains(where: { $0.index == currentWordIndex }) ?? false
                let currentLineContainsCursor = currentLine.contains(where: { $0.index == currentWordIndex })
                if !lastLineContainsCursor && !currentLineContainsCursor && allLines.count > 3 {
                    // We have enough lines past the cursor
                    break
                }
            }
        }
        if !currentLine.isEmpty {
            allLines.append(currentLine)
        }

        // Find which line has the current word
        let cursorLineIndex = allLines.firstIndex { line in
            line.contains { $0.index == currentWordIndex }
        } ?? 0

        // Show current line + 2 after
        let start = cursorLineIndex
        let end = min(start + 3, allLines.count)
        return Array(allLines[start..<end])
    }
}
