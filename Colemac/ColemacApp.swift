import SwiftData
import SwiftUI

@main
struct ColemacApp: App {
    let container: ModelContainer

    init() {
        do {
            let container = try ModelContainer(for: Session.self)
            self.container = container
            Self.backfillWordsTyped(context: container.mainContext)
        } catch {
            // Schema migration failed — delete the old store and recreate
            let url = URL.applicationSupportDirectory.appending(path: "default.store")
            for ext in ["", "-wal", "-shm"] {
                try? FileManager.default.removeItem(at: url.deletingLastPathComponent().appending(path: "default.store\(ext)"))
            }
            container = try! ModelContainer(for: Session.self)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .font(AppTheme.monoFont)
        }
        .modelContainer(container)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }

    /// Backfill wordsTyped for existing sessions using wpm * (duration / 60)
    private static func backfillWordsTyped(context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(predicate: #Predicate { $0.wordsTyped == nil })
        guard let sessions = try? context.fetch(descriptor) else { return }
        for session in sessions {
            session.wordsTyped = session.duration > 0 ? max(1, Int(session.wpm * (session.duration / 60.0))) : 0
        }
        try? context.save()
    }
}
