import Foundation
import Observation

enum SessionMode: Hashable {
    case time(seconds: Int)
    case words(count: Int)
    case zen

    var label: String {
        switch self {
        case let .time(s): return "\(s)"
        case let .words(c): return "\(c)"
        case .zen: return "Zen"
        }
    }

    static let allOptions: [SessionMode] = [
        .time(seconds: 15), .time(seconds: 30), .time(seconds: 60), .time(seconds: 120),
        .words(count: 10), .words(count: 25), .words(count: 50), .words(count: 100),
        .zen,
    ]

    var isZen: Bool {
        if case .zen = self { return true }
        return false
    }

    var storageLabel: String {
        switch self {
        case let .time(s): return "time \(s)"
        case let .words(c): return "words \(c)"
        case .zen: return "zen"
        }
    }
}

@Observable
class TypingState {
    var words: [String] = []
    var currentWordIndex: Int = 0
    var currentCharIndex: Int = 0
    var typedChars: [[CharResult]] = []
    var startTime: Date?
    var isActive: Bool = false
    var isFinished: Bool = false
    var currentLevel: Level = .all[0]
    var sessionMode: SessionMode = .time(seconds: 30)
    var totalKeystrokes: Int = 0
    var correctKeystrokes: Int = 0
    var mistypedKeys: [String: Int] = [:]
    var remainingTime: TimeInterval = 0
    var endTime: Date?

    var currentWord: String {
        guard currentWordIndex < words.count else { return "" }
        return words[currentWordIndex]
    }

    var wpm: Double {
        guard startTime != nil else { return 0 }
        let elapsed = elapsedTime / 60.0
        guard elapsed > 0.05 else { return 0 }
        return (Double(correctKeystrokes) / 5.0) / elapsed
    }

    var accuracy: Double {
        guard totalKeystrokes > 0 else { return 100 }
        return (Double(correctKeystrokes) / Double(totalKeystrokes)) * 100
    }

    var elapsedTime: TimeInterval {
        guard let start = startTime else { return 0 }
        let end = endTime ?? Date()
        return end.timeIntervalSince(start)
    }

    var wordsCompleted: Int {
        currentWordIndex
    }

    var targetWords: Int? {
        if case let .words(count) = sessionMode { return count }
        return nil
    }

    var targetSeconds: Int? {
        if case let .time(s) = sessionMode { return s }
        return nil
    }
}

enum CharResult {
    case correct
    case incorrect
}
