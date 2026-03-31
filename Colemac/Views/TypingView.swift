import SwiftUI

private struct CursorPositionKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

struct TypingView: View {
    @Bindable var engine: TypingEngine
    @AppStorage("smoothCursor") private var smoothCursor = true
    @FocusState private var isFocused: Bool
    @State private var cursorVisible = true
    @State private var cursorFrame: CGRect = .zero
    @State private var idleTimer: Timer?
    @State private var blinkTimer: Timer?
    @State private var deleteMonitor: Any?
    @AppStorage("showKeyboard") private var showKeyboard = true

    private var isZen: Bool {
        engine.state.sessionMode.isZen
    }

    private var sessionProgress: Double {
        switch engine.state.sessionMode {
        case let .time(seconds):
            guard engine.state.startTime != nil else { return 0 }
            let elapsed = engine.state.elapsedTime
            return min(elapsed / Double(seconds), 1.0)
        case let .words(count):
            guard count > 0 else { return 0 }
            return min(Double(engine.state.wordsCompleted) / Double(count), 1.0)
        case .zen:
            return 0
        case .custom:
            return min(Double(engine.state.wordsCompleted) / 50.0, 1.0)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let scale = max(0.6, geo.size.width / 900)

            VStack(spacing: 0) {
                Spacer()

                if engine.state.isFinished {
                    ResultView(
                        scale: scale,
                        wpm: engine.state.wpm,
                        accuracy: engine.state.accuracy,
                        wordsCompleted: engine.state.wordsCompleted,
                        elapsedTime: engine.state.elapsedTime
                    )
                } else {
                    wordDisplay(scale: scale, containerWidth: geo.size.width)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(24 * scale)

                    KeyboardView(currentLevel: engine.state.currentLevel)
                        .frame(height: 120 * scale)
                        .opacity(0.8)
                        .padding(.horizontal, 24 * scale)
                }

                Spacer()

                if showKeyboard && !engine.state.isFinished {
                    KeyboardView(currentLevel: engine.state.currentLevel)
                        .frame(maxHeight: geo.size.height * 0.3)
                        .padding(.bottom, 8)
                }

                if !isZen && !engine.state.isFinished {
                    statsBar
                }

                if isZen && engine.state.isActive && !engine.state.isFinished {
                    Text("tab to exit zen")
                        .font(AppTheme.monoFontSmall)
                        .foregroundColor(AppTheme.subtleText.opacity(0.4))
                        .padding(.bottom, 12)
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
            deleteMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 51 { // backspace key
                    engine.handleBackspace()
                    resetCursorBlink()
                    return nil // consume the event
                }
                return event
            }
        }
        .onDisappear {
            idleTimer?.invalidate()
            blinkTimer?.invalidate()
            idleTimer = nil
            blinkTimer = nil
            if let monitor = deleteMonitor {
                NSEvent.removeMonitor(monitor)
                deleteMonitor = nil
            }
        }
        .onKeyPress(.space) {
            if engine.state.isFinished {
                engine.reset()
                cursorFrame = .zero
                isFocused = true
                return .handled
            }
            resetCursorBlink()
            return engine.handleKeyPress(" ") ? .handled : .ignored
        }
        .onKeyPress(.escape) {
            if engine.state.isActive && !engine.state.isFinished {
                engine.reset()
                cursorFrame = .zero
                isFocused = true
                startCursorBlink()
            }
            return .handled
        }
        .onKeyPress(characters: .alphanumerics.union(.punctuationCharacters)) { press in
            if press.modifiers.contains(.shift) && press.characters.uppercased() == "M" {
                showKeyboard.toggle()
                return .handled
            }
            let key = press.characters
            guard !key.isEmpty else { return .ignored }
            resetCursorBlink()
            return engine.handleKeyPress(key) ? .handled : .ignored
        }
    }

    // MARK: - Word display

    private func wordDisplay(scale: CGFloat, containerWidth: CGFloat) -> some View {
        let fontSize = 24 * scale
        let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        let charWidth = font.advancement(forGlyph: font.glyph(withName: "space")).width
        let maxWidth = containerWidth - (48 * scale) // account for padding

        let lines = visibleLines(charWidth: charWidth, maxWidth: maxWidth)

        return VStack(alignment: .leading, spacing: 8 * scale) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { wordOffset, wordInfo in
                        if wordOffset > 0 {
                            let prevIndex = line[wordOffset - 1].index
                            let spaceColor = prevIndex < engine.state.currentWordIndex
                                ? AppTheme.correctText
                                : AppTheme.untypedText
                            let cursorOnSpace = prevIndex == engine.state.currentWordIndex
                                && engine.state.currentCharIndex >= engine.state.currentWord.count

                            Text(" ")
                                .font(.system(size: fontSize, design: .monospaced))
                                .foregroundColor(spaceColor)
                                .background {
                                    if cursorOnSpace {
                                        GeometryReader { geo in
                                            Color.clear.preference(
                                                key: CursorPositionKey.self,
                                                value: geo.frame(in: .named("wordDisplay"))
                                            )
                                        }
                                    }
                                }
                        }
                        wordView(wordIndex: wordInfo.index, word: wordInfo.word, fontSize: fontSize)
                    }
                }
            }
        }
        .coordinateSpace(name: "wordDisplay")
        .onPreferenceChange(CursorPositionKey.self) { frame in
            if smoothCursor {
                withAnimation(.easeOut(duration: 0.09)) {
                    cursorFrame = frame
                }
            } else {
                cursorFrame = frame
            }
        }
        .overlay {
            if cursorFrame != .zero && cursorVisible {
                Rectangle()
                    .fill(AppTheme.cursorColor)
                    .frame(width: 2, height: cursorFrame.height)
                    .position(x: cursorFrame.minX, y: cursorFrame.midY)
            }
        }
    }

    private func wordView(wordIndex: Int, word: String, fontSize: CGFloat) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(word.enumerated()), id: \.offset) { charIndex, char in
                let color = charColor(wordIndex: wordIndex, charIndex: charIndex)
                let isCursor = wordIndex == engine.state.currentWordIndex && charIndex == engine.state.currentCharIndex

                Text(String(char))
                    .font(.system(size: fontSize, design: .monospaced))
                    .foregroundColor(color)
                    .background {
                        if isCursor {
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: CursorPositionKey.self,
                                    value: geo.frame(in: .named("wordDisplay"))
                                )
                            }
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
        HStack {
            HStack(spacing: 32) {
                if let _ = engine.state.targetSeconds, engine.state.startTime != nil {
                    statItem(label: "", value: formatDuration(engine.state.remainingTime))
                } else if case let .words(target) = engine.state.sessionMode {
                    statItem(label: "/ \(target)", value: "\(engine.state.wordsCompleted)")
                } else if case .custom = engine.state.sessionMode {
                    statItem(label: "/ 50", value: "\(engine.state.wordsCompleted)")
                }

                statItem(label: "wpm", value: String(format: "%.0f", engine.state.wpm))
                statItem(label: "acc", value: String(format: "%.0f%%", engine.state.accuracy))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProgressView(value: sessionProgress)
                .tint(AppTheme.accentGreen)
                .frame(width: 200)
                .frame(maxWidth: .infinity, alignment: .center)

            Button("reset") {
                engine.reset()
                isFocused = true
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.subtleText)
            .font(AppTheme.monoFontSmall)
            .withHover()
            .frame(maxWidth: .infinity, alignment: .trailing)
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

    private func resetCursorBlink() {
        // Stop any existing blink
        blinkTimer?.invalidate()
        blinkTimer = nil
        cursorVisible = true

        // After 0.25s idle, start blinking
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { _ in
            DispatchQueue.main.async {
                startBlinking()
            }
        }
    }

    private func startBlinking() {
        blinkTimer?.invalidate()
        cursorVisible = true
        blinkTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            DispatchQueue.main.async {
                cursorVisible.toggle()
            }
        }
    }

    private func startCursorBlink() {
        // Initial state: start blinking right away (no typing yet)
        startBlinking()
    }

    private func formatDuration(_ t: TimeInterval) -> String {
        let total = Int(t)
        let mins = total / 60
        let secs = total % 60
        return mins > 0 ? "\(mins):\(String(format: "%02d", secs))" : "\(secs)s"
    }

    // MARK: - Helpers

    static func makePreviewEngine(finished: Bool = false) -> TypingEngine {
        let engine = TypingEngine()
        engine.start(level: Level.all[0], mode: .words(count: 25))
        if finished {
            // Simulate some typing then finish
            engine.state.totalKeystrokes = 120
            engine.state.correctKeystrokes = 115
            engine.state.startTime = Date().addingTimeInterval(-45)
            engine.state.currentWordIndex = 25
            engine.finish()
        } else {
            // Simulate partially typed
            engine.state.startTime = Date().addingTimeInterval(-10)
            engine.state.currentWordIndex = 3
            engine.state.currentCharIndex = 2
            engine.state.totalKeystrokes = 20
            engine.state.correctKeystrokes = 18
            for i in 0 ..< 3 {
                let word = engine.state.words[i]
                engine.state.typedChars[i] = word.map { _ in .correct }
            }
            engine.state.typedChars[3] = [.correct, .incorrect]
        }
        return engine
    }

    // MARK: - Line splitting

    struct WordInfo {
        let index: Int
        let word: String
    }

    private func visibleLines(charWidth: CGFloat, maxWidth: CGFloat) -> [[WordInfo]] {
        let words = engine.state.words
        let currentWordIndex = engine.state.currentWordIndex

        // Build all lines
        var allLines: [[WordInfo]] = []
        var currentLine: [WordInfo] = []
        var lineWidth: CGFloat = 0

        for i in 0 ..< words.count {
            let word = words[i]
            let wordWidth = CGFloat(word.count) * charWidth
            let spaceWidth = currentLine.isEmpty ? 0 : charWidth

            if lineWidth + spaceWidth + wordWidth > maxWidth, !currentLine.isEmpty {
                allLines.append(currentLine)
                currentLine = []
                lineWidth = 0
            }

            currentLine.append(WordInfo(index: i, word: word))
            lineWidth += spaceWidth + wordWidth
        }
        if !currentLine.isEmpty {
            allLines.append(currentLine)
        }

        // Find which line has the current word
        let cursorLineIndex = allLines.firstIndex { line in
            line.contains { $0.index == currentWordIndex }
        } ?? 0

        // Cursor stays on the middle line (index 1 of 3).
        // Once cursor moves past the first line, pin it to the middle.
        let start = max(0, cursorLineIndex - 1)
        let end = min(start + 3, allLines.count)
        return Array(allLines[start ..< end])
    }
}

#Preview("Typing") {
    TypingView(engine: TypingView.makePreviewEngine())
        .frame(width: 800, height: 400)
}

#Preview("Finished") {
    TypingView(engine: TypingView.makePreviewEngine(finished: true))
        .frame(width: 800, height: 400)
}
