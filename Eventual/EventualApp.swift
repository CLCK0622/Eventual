// EventualApp.swift
import SwiftUI
import SwiftData

@main
struct EventualApp: App {
    // 使用我们刚才写的共享容器工厂方法
    let container = SharedModelContainer.create()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // 注入共享容器
        .modelContainer(container)
    }
}
