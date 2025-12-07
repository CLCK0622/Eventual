import SwiftData
import Foundation

class SharedModelContainer {
    static let appGroupIdentifier = "group.com.clckkkkk.Eventual"
    
    static let cloudKitContainerIdentifier = "iCloud.com.clckkkkk.Eventual"

    static func create() -> ModelContainer {
        let schema = Schema([Event.self])
        
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("Critical Error: Cannot access App Group container. Check Entitlements and Group ID.")
            fatalError("Failed to create URL for App Group container.")
        }
        
        let storeURL = containerURL.appendingPathComponent("Eventual.sqlite")
        print("📂 Database Path: \(storeURL.path)")

        try? FileManager.default.createDirectory(at: storeURL.deletingLastPathComponent(), withIntermediateDirectories: true)

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .automatic
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            return container
        } catch {
            print("Failed to create ModelContainer: \(error)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
