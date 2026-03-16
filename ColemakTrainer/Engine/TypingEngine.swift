import Foundation

@Observable
class TypingEngine {
    var state = TypingState()
    private var timer: Timer?

    func start(level: Level, mode: SessionMode) {
        stopTimer()
        state = TypingState()
        state.currentLevel = level
        state.sessionMode = mode
        state.words = WordList.generatePracticeWords(for: level, count: 200)
        state.typedChars = state.words.map { _ in [] }
        state.isActive = true
        state.isFinished = false

        if case .time(let seconds) = mode {
            state.remainingTime = TimeInterval(seconds)
        }
    }

    // QWERTY physical key → Colemak character
    private static let qwertyToColemak: [Character: Character] = [
        "e": "f", "r": "p", "t": "g", "y": "j", "u": "l", "i": "u", "o": "y", "p": ";",
        "s": "r", "d": "s", "f": "t", "g": "d", "j": "n", "k": "e", "l": "i", ";": "o",
        "n": "k",
    ]

    private func mapToColemak(_ key: String) -> String {
        guard let char = key.first,
              let mapped = Self.qwertyToColemak[char] else {
            return key
        }
        return String(mapped)
    }

    func handleKeyPress(_ key: String) -> Bool {
        guard state.isActive, !state.isFinished else { return false }

        if state.startTime == nil {
            state.startTime = Date()
            startTimerIfNeeded()
        }

        if key == " " {
            return handleSpace()
        }

        let mapped = mapToColemak(key)
        return handleCharacter(mapped)
    }

    func handleBackspace() {
        guard state.isActive, !state.isFinished else { return }

        if state.currentCharIndex > 0 {
            state.currentCharIndex -= 1
            if let removed = state.typedChars[state.currentWordIndex].popLast() {
                state.totalKeystrokes -= 1
                if removed == .correct {
                    state.correctKeystrokes -= 1
                }
            }
        } else if state.currentWordIndex > 0 {
            state.currentWordIndex -= 1
            state.currentCharIndex = state.typedChars[state.currentWordIndex].count
        }
    }

    func reset() {
        start(level: state.currentLevel, mode: state.sessionMode)
    }

    func finish() {
        state.endTime = Date()
        state.isFinished = true
        state.isActive = false
        stopTimer()
    }

    // MARK: - Timer

    private func startTimerIfNeeded() {
        guard case .time = state.sessionMode else { return }
        stopTimer()
        let t = Timer(timeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            guard !self.state.isFinished,
                  let start = self.state.startTime,
                  let target = self.state.targetSeconds else {
                timer.invalidate()
                return
            }
            let elapsed = Date().timeIntervalSince(start)
            let remaining = TimeInterval(target) - elapsed
            self.state.remainingTime = max(0, remaining)
            if remaining <= 0 {
                self.finish()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Private

    private func handleSpace() -> Bool {
        let word = state.currentWord
        guard state.currentCharIndex > 0 else { return false }

        if state.currentCharIndex < word.count {
            let remaining = word.count - state.currentCharIndex
            state.totalKeystrokes += remaining
        }

        state.currentWordIndex += 1
        state.currentCharIndex = 0

        // Check word-based completion
        if case .words(let target) = state.sessionMode {
            if state.wordsCompleted >= target {
                finish()
                return true
            }
        }

        // Generate more words if running low
        if state.currentWordIndex >= state.words.count - 20 {
            let more = WordList.generatePracticeWords(for: state.currentLevel, count: 50)
            state.words.append(contentsOf: more)
            state.typedChars.append(contentsOf: more.map { _ in [] })
        }

        return true
    }

    private func handleCharacter(_ key: String) -> Bool {
        let word = state.currentWord
        guard state.currentCharIndex < word.count else { return false }

        let expected = String(word[word.index(word.startIndex, offsetBy: state.currentCharIndex)])
        let isCorrect = key == expected

        state.totalKeystrokes += 1
        if isCorrect {
            state.correctKeystrokes += 1
            state.typedChars[state.currentWordIndex].append(.correct)
        } else {
            state.typedChars[state.currentWordIndex].append(.incorrect)
            state.mistypedKeys[expected, default: 0] += 1
        }

        state.currentCharIndex += 1
        return true
    }
}
