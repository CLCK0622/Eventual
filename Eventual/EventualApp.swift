
import SwiftUI
import SwiftData

@main
struct EventualApp: App {
    let container = SharedModelContainer.create()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
