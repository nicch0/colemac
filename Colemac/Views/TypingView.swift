import SwiftUI

struct TypingView: View {
    @Bindable var engine: TypingEngine
    @FocusState private var isFocused: Bool
    @State private var cursorVisible = true
    @State private var idleTimer: Timer?
    @State private var blinkTimer: Timer?
    @State private var deleteMonitor: Any?
    @State private var showKeyboard = false
    @State private var showResults = false

    private var isZen: Bool {
        engine.state.sessionMode.isZen
    }

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

                if showKeyboard && !engine.state.isFinished {
                    KeyboardView(currentLevel: engine.state.currentLevel)
                        .frame(maxHeight: geo.size.height * 0.3)
                        .padding(.bottom, 8)
                }

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
                isFocused = true
                return .handled
            }
            resetCursorBlink()
            return engine.handleKeyPress(" ") ? .handled : .ignored
        }
        .onKeyPress(.escape) {
            if isZen {
                engine.finish()
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

    // MARK: - Results

    private func resultsView(scale: CGFloat) -> some View {
        VStack(spacing: 16 * scale) {
            Text(String(format: "%.0f", showResults ? engine.state.wpm : 0))
                .font(.system(size: 64 * scale, design: .monospaced))
                .foregroundColor(AppTheme.accentGreen)
                .contentTransition(.numericText(value: showResults ? engine.state.wpm : 0))
            Text("wpm")
                .font(.system(size: 20 * scale, design: .monospaced))
                .foregroundColor(AppTheme.subtleText)

            HStack(spacing: 32 * scale) {
                resultItem("accuracy", String(format: "%.0f%%", engine.state.accuracy), scale: scale)
                resultItem("words", "\(engine.state.wordsCompleted)", scale: scale)
                resultItem("time", formatDuration(engine.state.elapsedTime), scale: scale)
            }
            .padding(.top, 8 * scale)

            HStack(spacing: 8) {
                Text("again")
                    .font(.system(size: 20 * scale, design: .monospaced))
                    .foregroundColor(AppTheme.accentGreen)
                Text("(space)")
                    .font(.system(size: 14 * scale, design: .monospaced))
                    .foregroundColor(AppTheme.subtleText)
            }
            .padding(.top, 24 * scale)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                showResults = true
            }
        }
        .onDisappear {
            showResults = false
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
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                HStack(spacing: 0) {
                    ForEach(Array(line.enumerated()), id: \.offset) { wordOffset, wordInfo in
                        if wordOffset > 0 {
                            let prevIndex = line[wordOffset - 1].index
                            let spaceColor = prevIndex < engine.state.currentWordIndex
                                ? AppTheme.correctText
                                : AppTheme.untypedText
                            Text(" ")
                                .font(.system(size: fontSize, design: .monospaced))
                                .foregroundColor(spaceColor)
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
            } else if case let .words(target) = engine.state.sessionMode {
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
            .modifier(AppTheme.pointerCursor)
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

            // Stop building lines once we have enough ahead of cursor
            if i > currentWordIndex + 3 {
                let cursorFound = allLines.contains { line in
                    line.contains { $0.index == currentWordIndex }
                } || currentLine.contains { $0.index == currentWordIndex }
                if cursorFound, allLines.count > 3 {
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
        return Array(allLines[start ..< end])
    }
}
