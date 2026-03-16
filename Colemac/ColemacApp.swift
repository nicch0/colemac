import SwiftUI
import SwiftData

@main
struct ColemacApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Session.self)
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 600)
    }
}
