import Foundation
import SwiftData

@Model
class Session {
    var date: Date
    var level: Int
    var wpm: Double
    var accuracy: Double
    var duration: TimeInterval
    var totalKeystrokes: Int
    var correctKeystrokes: Int
    var mistypedKeys: [String: Int]
    var wordsTyped: Int?

    init(date: Date = .now, level: Int, wpm: Double, accuracy: Double, duration: TimeInterval, totalKeystrokes: Int, correctKeystrokes: Int, mistypedKeys: [String: Int] = [:], wordsTyped: Int? = nil) {
        self.date = date
        self.level = level
        self.wpm = wpm
        self.accuracy = accuracy
        self.duration = duration
        self.totalKeystrokes = totalKeystrokes
        self.correctKeystrokes = correctKeystrokes
        self.mistypedKeys = mistypedKeys
        self.wordsTyped = wordsTyped
    }
}
