import SwiftData
import SwiftUI

struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Session.date, order: .reverse) private var sessions: [Session]
    @State private var selected: Set<PersistentIdentifier> = []
    @State private var chartAnimated = false
    @State private var selectedLevelIndex: Double = 0

    private var selectedLevel: Level? {
        let index = Int(selectedLevelIndex)
        if index == 0 { return nil }
        return Level.all[index - 1]
    }

    private var filteredSessions: [Session] {
        guard let level = selectedLevel else { return sessions }
        return sessions.filter { $0.level == level.id }
    }

    private var chronologicalSessions: [Session] {
        filteredSessions.reversed()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if sessions.count >= 2 {
                VStack(alignment: .leading, spacing: 8) {
                    LevelChart(sessions: chronologicalSessions, animated: chartAnimated)
                        .onAppear {
                            withAnimation(.snappy) {
                                chartAnimated = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .center)

                    HStack(spacing: 8) {
                        Text(selectedLevel.map { "Level \($0.id): \($0.name)" } ?? "All Levels")
                            .font(AppTheme.monoFontSmall)
                            .foregroundColor(AppTheme.subtleText)
                            .frame(width: 140, alignment: .leading)

                        Slider(value: $selectedLevelIndex, in: 0 ... Double(Level.all.count), step: 1)
                            .tint(AppTheme.accentGreen)
                    }
                }
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.6 }
                .padding(.bottom, 12)
            }

            SessionHistoryTable(
                sessions: sessions,
                modelContext: modelContext,
                selected: $selected
            )
        }
        .overlay {
            if sessions.isEmpty {
                Text("No sessions yet. Complete a round to save stats.")
                    .font(AppTheme.monoFontSmall)
                    .foregroundColor(AppTheme.subtleText)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
