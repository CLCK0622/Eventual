//
//  SharedModelContainer.swift
//  Eventual
//
//  Created by Yi Zhong on 11/9/25.
//


// SharedModelContainer.swift
import SwiftData
import Foundation

// 这个工具类负责创建配置好的 ModelContainer
class SharedModelContainer {
    // 将你的 App Group ID 替换到这里
    static let appGroupIdentifier = "group.com.clckkkkk.Eventual"

    static func create() -> ModelContainer {
        let schema = Schema([Event.self])
        let modelConfiguration: ModelConfiguration
        
        // 尝试找到 App Group 的共享目录
        if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            // 将数据库文件放在共享目录下
            let storeURL = containerURL.appendingPathComponent("Eventual.sqlite")
            modelConfiguration = ModelConfiguration(url: storeURL, allowsSave: true)
        } else {
            // 如果找不到（比如在某些模拟器环境下），回退到默认位置，但打印一个警告
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
