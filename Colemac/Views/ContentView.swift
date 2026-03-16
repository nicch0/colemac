import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = TypingEngine()
    @State private var selectedLevel = Level.all[0]
    @State private var selectedMode: SessionMode = .time(seconds: 30)
    @State private var showStats = false

    var body: some View {
        VStack(spacing: 0) {
            // Top bar (hidden in zen mode while typing)
            if !selectedMode.isZen || !engine.state.isActive || engine.state.isFinished {
                toolbar
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
            }
        }
        .onAppear {
            engine.start(level: selectedLevel, mode: selectedMode)
        }
    }

    private var toolbar: some View {
        HStack(spacing: 16) {
            Button("Colemac") {
                showStats = false
            }
            .buttonStyle(.plain)
            .font(AppTheme.monoFont)
            .foregroundColor(AppTheme.correctText)
            .modifier(AppTheme.pointerCursor)

            Spacer()

            if !showStats {
                modeSelector

                Spacer()

                Picker("", selection: $selectedLevel) {
                    ForEach(Level.all) { level in
                        Text("Level \(level.id): \(level.name)").tag(level)
                    }
                }
                .pickerStyle(.menu)
                .foregroundColor(AppTheme.correctText)
                .frame(width: 180)
            }

            Button(showStats ? "Practice" : "Stats") {
                showStats.toggle()
            }
            .buttonStyle(.plain)
            .foregroundColor(AppTheme.accentGreen)
            .font(AppTheme.monoFontSmall)
            .modifier(AppTheme.pointerCursor)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceBackground)
        .colorScheme(.dark)
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            modeGroup("time", [
                .time(seconds: 15), .time(seconds: 30),
                .time(seconds: 60), .time(seconds: 120),
            ])

            Text("|")
                .foregroundColor(AppTheme.subtleText)
                .font(AppTheme.monoFontSmall)
                .padding(.horizontal, 6)

            modeGroup("words", [
                .words(count: 10), .words(count: 25),
                .words(count: 50), .words(count: 100),
            ])

            Text("|")
                .foregroundColor(AppTheme.subtleText)
                .font(AppTheme.monoFontSmall)
                .padding(.horizontal, 6)

            modeButton(.zen)
        }
    }

    private func modeGroup(_: String, _ modes: [SessionMode]) -> some View {
        HStack(spacing: 2) {
            ForEach(modes, id: \.label) { mode in
                modeButton(mode)
            }
        }
    }

    private func modeButton(_ mode: SessionMode) -> some View {
        Button(mode.label) {
            selectedMode = mode
        }
        .buttonStyle(.plain)
        .font(AppTheme.monoFontSmall)
        .foregroundColor(selectedMode == mode ? AppTheme.accentGreen : AppTheme.subtleText)
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .modifier(AppTheme.pointerCursor)
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
            mistypedKeys: s.mistypedKeys
        )
        modelContext.insert(session)
    }
}
