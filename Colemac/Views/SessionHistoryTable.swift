import SwiftData
import SwiftUI

struct SessionHistoryTable: View {
    let sessions: [Session]
    let modelContext: ModelContext
    @Binding var selected: Set<PersistentIdentifier>
    @State private var rowFrames: [PersistentIdentifier: CGRect] = [:]
    @State private var dragStartIndex: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Session History")
                    .font(AppTheme.monoFont)
                    .foregroundColor(AppTheme.correctText)

                Spacer()

                if !selected.isEmpty {
                    Button("delete (\(selected.count))") {
                        deleteSelected()
                    }
                    .buttonStyle(.plain)
                    .font(AppTheme.monoFontSmall)
                    .foregroundColor(AppTheme.incorrectText)
                }
            }

            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        headerCell("", width: 24)
                        headerCell("Date", width: 140)
                        headerCell("Level", width: 50)
                        headerCell("WPM", width: 60)
                        headerCell("Words", width: 60)
                        headerCell("Acc", width: 60)
                        headerCell("Time", width: 60)
                        Spacer()
                    }
                    .padding(.bottom, 8)

                    ForEach(Array(sessions.enumerated()), id: \.element.persistentModelID) { _, session in
                        let isSelected = selected.contains(session.persistentModelID)

                        HStack {
                            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(isSelected ? AppTheme.accentGreen : AppTheme.subtleText)
                                .frame(width: 24)
                            dataCell(formatDate(session.date), width: 140)
                            dataCell("\(session.level)", width: 30)
                            dataCell(String(format: "%.0f", session.wpm), width: 60)
                            dataCell("\(session.wordsTyped ?? 0)", width: 60)
                            dataCell(String(format: "%.0f%%", session.accuracy), width: 60)
                            dataCell(formatDuration(session.duration), width: 60)
                            Spacer()
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        .background(isSelected ? Color.white.opacity(0.05) : .clear)
                        .cornerRadius(4)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: RowFrameKey.self,
                                    value: [session.persistentModelID: geo.frame(in: .named("list"))]
                                )
                            }
                        )
                    }
                }
                .coordinateSpace(name: "list")
                .onPreferenceChange(RowFrameKey.self) { frames in
                    rowFrames = frames
                }
                .gesture(
                    DragGesture(minimumDistance: 5, coordinateSpace: .named("list"))
                        .onChanged { value in
                            let startY = value.startLocation.y
                            let currentY = value.location.y
                            let minY = min(startY, currentY)
                            let maxY = max(startY, currentY)

                            if dragStartIndex == nil {
                                dragStartIndex = sessionIndex(at: startY)
                            }

                            var newSelection: Set<PersistentIdentifier> = []
                            for (id, frame) in rowFrames {
                                let rowMidY = frame.midY
                                if rowMidY >= minY, rowMidY <= maxY {
                                    newSelection.insert(id)
                                }
                            }
                            selected = newSelection
                        }
                        .onEnded { _ in
                            dragStartIndex = nil
                        }
                )
                .simultaneousGesture(
                    TapGesture()
                        .onEnded {}
                )
            }
            .onTapGesture { location in
                guard let tappedID = rowID(at: location) else {
                    selected = []
                    return
                }

                if NSEvent.modifierFlags.contains(.command) {
                    if selected.contains(tappedID) {
                        selected.remove(tappedID)
                    } else {
                        selected.insert(tappedID)
                    }
                } else {
                    if selected == [tappedID] {
                        selected = []
                    } else {
                        selected = [tappedID]
                    }
                }
            }
        }
    }

    private func sessionIndex(at y: CGFloat) -> Int? {
        for (index, session) in sessions.enumerated() {
            if let frame = rowFrames[session.persistentModelID], frame.contains(CGPoint(x: frame.midX, y: y)) {
                return index
            }
        }
        return nil
    }

    private func rowID(at location: CGPoint) -> PersistentIdentifier? {
        for (id, frame) in rowFrames {
            if frame.minY <= location.y, location.y <= frame.maxY {
                return id
            }
        }
        return nil
    }

    private func deleteSelected() {
        for session in sessions where selected.contains(session.persistentModelID) {
            modelContext.delete(session)
        }
        selected = []
    }

    private func headerCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(AppTheme.monoFontSmall)
            .foregroundColor(AppTheme.subtleText)
            .frame(width: width, alignment: .leading)
    }

    private func dataCell(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(AppTheme.monoFontSmall)
            .foregroundColor(AppTheme.correctText)
            .frame(width: width, alignment: .leading)
    }

    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "MMM d, h:mma"
        f.amSymbol = "am"
        f.pmSymbol = "pm"
        return f.string(from: date)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}

private struct RowFrameKey: PreferenceKey {
    static var defaultValue: [PersistentIdentifier: CGRect] = [:]
    static func reduce(value: inout [PersistentIdentifier: CGRect], nextValue: () -> [PersistentIdentifier: CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}
