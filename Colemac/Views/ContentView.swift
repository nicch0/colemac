import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var engine = TypingEngine()
    @State private var selectedLevel = Level.all[0]
    @State private var selectedMode: SessionMode = .words(count: 50)
    @State private var showStats = false
    @State private var showSettings = false
    @AppStorage("smoothCursor") private var smoothCursor = true
    @AppStorage("rememberLastLevel") private var rememberLastLevel = true
    @AppStorage("lastLevelId") private var lastLevelId = 1

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

            Button {
                showSettings.toggle()
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14))
                    .foregroundColor(AppTheme.subtleText)
            }
            .buttonStyle(.plain)
            .modifier(AppTheme.pointerCursor)
            .popover(isPresented: $showSettings) {
                settings
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .background(AppTheme.surfaceBackground)
        .colorScheme(.dark)
    }

    private var settings: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Settings")
                .font(AppTheme.monoFont)
                .foregroundColor(AppTheme.correctText)

            HStack {
                Text("Smooth cursor")
                Spacer()
                Toggle("", isOn: $smoothCursor)
                    .foregroundColor(AppTheme.correctText)
                    .toggleStyle(.switch)
            }
            .font(AppTheme.monoFontSmall)

            HStack {
                Text("Remember Last Level")
                Spacer()
                Toggle("", isOn: $rememberLastLevel)
                    .font(AppTheme.monoFontSmall)
                    .foregroundColor(AppTheme.correctText)
                    .toggleStyle(.switch)
            }
            .font(AppTheme.monoFontSmall)
        }
        .padding(16)
        .background(AppTheme.surfaceBackground)
    }

    private var modeSelector: some View {
        HStack(spacing: 2) {
            modeGroup("words", [
                .words(count: 10), .words(count: 25),
                .words(count: 50), .words(count: 100),
            ])

            Text("|")
                .foregroundColor(AppTheme.subtleText)
                .font(AppTheme.monoFontSmall)
                .padding(.horizontal, 6)

            modeGroup("time", [
                .time(seconds: 15), .time(seconds: 30),
                .time(seconds: 60), .time(seconds: 120),
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
