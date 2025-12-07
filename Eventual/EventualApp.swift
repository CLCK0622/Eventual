import SwiftUI
import SwiftData

@main
struct EventualApp: App {
    let container = SharedModelContainer.create()

    var body: some Scene {
        #if os(macOS)
        Window("Eventual", id: "main") {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .modelContainer(container)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        #else
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
        #endif
    }
}
