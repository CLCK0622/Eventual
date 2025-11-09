import SwiftData
import SwiftUI

// 1. 定义重复模式枚举
enum RepeatMode: String, CaseIterable, Codable {
    case none = "一次性"
    case weekly = "每周"
    case monthly = "每月"
    case yearly = "每年"
}

@Model
class Event {
    var id: UUID
    var title: String
    // 核心改动：重命名为 originalDate
    var originalDate: Date
    var colorHex: String
    var isAllDay: Bool
    var notes: String?
    var createdAt: Date
    var isPinned: Bool = false
    @Attribute(.externalStorage) var imageData: Data?
    // 核心改动：新增重复模式
    var repeatModeRaw: String = RepeatMode.none.rawValue

    init(title: String, targetDate: Date, color: Color = .blue, isAllDay: Bool = true, isPinned: Bool = false, repeatMode: RepeatMode = .none) {
        self.id = UUID()
        self.title = title
        self.originalDate = targetDate
        self.colorHex = color.toHex() ?? "#0000FF"
        self.isAllDay = isAllDay
        self.isPinned = isPinned
        self.repeatModeRaw = repeatMode.rawValue
        self.createdAt = Date()
    }

    var repeatMode: RepeatMode {
        get { RepeatMode(rawValue: repeatModeRaw) ?? .none }
        set { repeatModeRaw = newValue.rawValue }
    }

    var nextTargetDate: Date {
        let calendar = Calendar.current
        let now = Date()
        
        if repeatMode == .none {
            return originalDate
        }

        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: originalDate)
        
        switch repeatMode {
        case .weekly:
            let originalWeekday = calendar.component(.weekday, from: originalDate)
            return calendar.nextDate(after: now, matching: DateComponents(hour: components.hour, minute: components.minute, weekday: originalWeekday), matchingPolicy: .nextTime) ?? originalDate
        case .monthly:
            return calendar.nextDate(after: now, matching: DateComponents(day: components.day, hour: components.hour, minute: components.minute), matchingPolicy: .nextTime) ?? originalDate
        case .yearly:
            return calendar.nextDate(after: now, matching: DateComponents(month: components.month, day: components.day, hour: components.hour, minute: components.minute), matchingPolicy: .nextTime) ?? originalDate
        case .none:
            return originalDate
        }
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let nowStartOfDay = calendar.startOfDay(for: Date())
        let targetStartOfDay = calendar.startOfDay(for: nextTargetDate)
        let components = calendar.dateComponents([.day], from: nowStartOfDay, to: targetStartOfDay)
        return components.day ?? 0
    }
    
    var isToday: Bool {
        return daysRemaining == 0
    }
    
    var isExpired: Bool {
        return repeatMode == .none && daysRemaining < 0
    }
}
