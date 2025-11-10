
import SwiftUI
import SwiftData

@main
struct EventualApp: App {
    let container = SharedModelContainer.create()

    var body: some Scene {
        WindowGroup {
            ContentView()
            #if os(macOS)
            .frame(minWidth: 800, minHeight: 600)
            #endif
        }
        .modelContainer(container)
    }
}
