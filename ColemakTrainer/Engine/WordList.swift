import Foundation

enum WordList {
    static func words(for level: Level) -> [String] {
        allWords.filter { word in
            word.allSatisfy { level.unlockedKeys.contains($0) }
        }
    }

    static func generatePracticeWords(for level: Level, count: Int = 100) -> [String] {
        let available = words(for: level)
        guard !available.isEmpty else { return ["no", "words"] }
        return (0..<count).map { _ in available.randomElement()! }
    }

    static let allWords: [String] = [
        // Very common short words
        "the", "be", "to", "of", "and", "a", "in", "that", "have", "it",
        "for", "not", "on", "with", "he", "as", "you", "do", "at", "this",
        "but", "his", "by", "from", "they", "we", "her", "she", "or", "an",
        "will", "my", "one", "all", "would", "there", "their", "what", "so",
        "up", "out", "if", "about", "who", "get", "which", "go", "me",
        "when", "make", "can", "like", "time", "no", "just", "him", "know",
        "take", "people", "into", "year", "your", "good", "some", "could",
        "them", "see", "other", "than", "then", "now", "look", "only",
        "come", "its", "over", "think", "also", "back", "after", "use",
        "two", "how", "our", "work", "first", "well", "way", "even", "new",
        "want", "because", "any", "these", "give", "day", "most", "us",

        // Common words - expanded
        "are", "is", "was", "were", "been", "being", "has", "had", "did",
        "does", "done", "say", "said", "says", "goes", "went", "gone",
        "get", "got", "gets", "let", "lets", "put", "set", "run", "ran",
        "sit", "sat", "sit", "stand", "stood", "tell", "told", "ask",
        "asked", "try", "tried", "need", "needed", "feel", "felt", "left",
        "hand", "high", "keep", "last", "long", "great", "old", "big",
        "small", "still", "own", "place", "end", "home", "read", "head",
        "start", "might", "story", "far", "sea", "hard", "near", "add",
        "food", "between", "state", "never", "began", "side", "kind",
        "white", "tree", "night", "life", "few", "north", "open", "seem",
        "together", "next", "stop", "both", "feet", "under", "ten",
        "often", "turn", "here", "thing", "name", "line", "above", "per",

        // More common English words
        "air", "rain", "rest", "stone", "train", "ten", "rise", "note",
        "sit", "ran", "iron", "root", "real", "toss", "rent", "neat",
        "noise", "store", "rain", "stair", "nose", "torn", "tire", "ore",
        "son", "ton", "one", "tin", "tie", "toe", "sin", "sir", "set",
        "net", "not", "nor", "ion", "inn", "its", "ore", "oar",
        "eat", "ear", "era", "err", "ire", "art", "ant", "ate",

        // Words good for home row (arstneio)
        "star", "rain", "train", "stain", "noise", "raise", "stone",
        "store", "stare", "snore", "stern", "torn", "sort", "snort",
        "toast", "roast", "ratio", "ration", "nation", "station",
        "tire", "entire", "series", "reason", "season", "treason",
        "orient", "senior", "tension", "inner", "sinner", "retire",
        "insert", "inert", "resist", "insist", "assist", "sister",
        "artist", "iris", "risen", "raisin", "satin", "saint",
        "retain", "attain", "obtain", "stain", "strain", "restrain",
        "terrain", "entertain", "interstate",

        // Words with d, h
        "the", "this", "that", "then", "than", "there", "these", "those",
        "think", "thing", "third", "their", "other", "another",
        "hand", "head", "heart", "hear", "high", "his", "her", "here",
        "hide", "hit", "hold", "hot", "had", "has", "hate", "date",
        "did", "die", "dish", "door", "done", "down", "draw", "end",
        "head", "shed", "shred", "thread", "dread", "tread",
        "thirst", "thrash", "shatter", "shorten", "haste",
        "shared", "hinder", "honored", "hardest", "handset",
        "shine", "shore", "shade", "share", "shirt", "short",

        // Words with p, g, j, l
        "page", "pale", "plan", "play", "please", "plot", "point",
        "glass", "glad", "gone", "gold", "goal", "large", "girl",
        "join", "just", "jolt", "jig", "jar", "jest", "judge",
        "long", "line", "light", "land", "last", "late", "let",
        "leg", "lip", "list", "listen", "little", "live", "lion",
        "people", "simple", "apple", "triple", "single", "gentle",
        "jungle", "angle", "eagle", "giggle", "jingle", "glimpse",
        "pledge", "plunge", "grip", "grasp", "grill", "gallop",

        // Words with c, v, b, k
        "back", "black", "block", "book", "break", "bring", "brick",
        "cave", "voice", "cover", "curve", "vast", "visit", "vote",
        "kick", "king", "bike", "cake", "lake", "like", "make",
        "clock", "click", "crack", "check", "chicken", "blanket",
        "basket", "bucket", "cabinet", "velvet", "vibrant",
        "visible", "victim", "vaccine", "vacant", "vivid",

        // Words with w, f, u, y
        "way", "water", "want", "wait", "walk", "wall", "war",
        "few", "find", "fire", "first", "fish", "five", "fly",
        "funny", "full", "future", "fuel", "fun", "fur", "fuse",
        "why", "would", "write", "wrong", "youth", "year", "yes",
        "you", "your", "young", "yet", "yellow", "yesterday",
        "wife", "wolf", "swift", "wafer", "flower", "follow",
        "fury", "fifty", "forty", "windy", "yawn", "frown",

        // Words with q, z, x, m
        "quiz", "queen", "quick", "quiet", "quite", "quote",
        "zero", "zone", "zoom", "zip", "zeal",
        "mix", "box", "fix", "tax", "six", "next", "text", "exit",
        "exam", "exact", "extra", "extreme", "excite", "except",
        "maze", "size", "prize", "freeze", "breeze",
        "make", "more", "most", "much", "many", "must", "may",
        "move", "music", "month", "money", "market", "master",
        "might", "mind", "minute", "modern", "moment", "machine",
        "maximum", "minimum", "mixture", "message", "method",
    ]
}
