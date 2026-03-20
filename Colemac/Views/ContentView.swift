import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = TypingEngine()
    @State private var selectedLevel = Level.all[0]
    @State private var selectedMode: SessionMode = .words(count: 50)
    @State private var showStats = false
    @State private var showSettings = false
    @AppStorage("rememberLastLevel") private var rememberLastLevel = true
    @AppStorage("lastLevelId") private var lastLevelId = 1

    var body: some View {
        VStack(spacing: 0) {
            // Top bar (hidden in zen mode while typing)
            if !selectedMode.isZen || !engine.state.isActive || engine.state.isFinished {
                ToolbarView(
                    showStats: $showStats,
                    showSettings: $showSettings,
                    selectedLevel: $selectedLevel,
                    selectedMode: $selectedMode
                )
            }

            // Main content
            if showStats {
                StatsView()
                    .frame(maxHeight: .infinity)
            } else {
                TypingView(engine: engine)
                    .frame(maxHeight: .infinity)
            }
        }
        .background(AppTheme.background)
        .onChange(of: selectedLevel) { _, newLevel in
            engine.start(level: newLevel, mode: selectedMode)
        }
        .onChange(of: selectedMode) { _, newMode in
            engine.start(level: selectedLevel, mode: newMode)
        }
        .onChange(of: engine.state.isFinished) { _, finished in
            if finished, engine.state.totalKeystrokes > 0 {
                saveSession()
                if rememberLastLevel {
                    lastLevelId = selectedLevel.id
                }
            }
        }
        .onAppear {
            if rememberLastLevel, let level = Level.all.first(where: { $0.id == lastLevelId }) {
                selectedLevel = level
            }
            engine.start(level: selectedLevel, mode: selectedMode)
        }
        .onKeyPress(.escape) {
            if showStats {
                showStats = false
                return .handled
            }
            return .ignored
        }
    }

    private func saveSession() {
        let s = engine.state
        let session = Session(
            level: s.currentLevel.id,
            wpm: s.wpm,
            accuracy: s.accuracy,
            duration: s.elapsedTime,
            totalKeystrokes: s.totalKeystrokes,
            correctKeystrokes: s.correctKeystrokes,
            mistypedKeys: s.mistypedKeys,
            wordsTyped: s.wordsCompleted,
            mode: s.sessionMode.storageLabel
        )
        modelContext.insert(session)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Session.self, inMemory: true)
        .frame(width: 900, height: 500)
}
