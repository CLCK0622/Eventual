//
//  SharedModelContainer.swift
//  Eventual
//
//  Created by Yi Zhong on 11/9/25.
//

import SwiftData
import Foundation

class SharedModelContainer {
    static let appGroupIdentifier = "group.com.clckkkkk.Eventual"

    static func create() -> ModelContainer {
        let schema = Schema([Event.self])
        let modelConfiguration: ModelConfiguration
        
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let storeURL = containerURL.appendingPathComponent("Eventual.sqlite")
            modelConfiguration = ModelConfiguration(url: storeURL, allowsSave: true)
        } else {
            print("Warning: Could not find App Group container. Using default store location.")
            modelConfiguration = ModelConfiguration()
        }

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
