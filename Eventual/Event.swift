import SwiftData
import SwiftUI

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
    var originalDate: Date
    var colorHex: String
    var notes: String?
    var createdAt: Date
    var isPinned: Bool = false
    @Attribute(.externalStorage) var imageData: Data?
    var repeatModeRaw: String = RepeatMode.none.rawValue

    init(title: String, targetDate: Date, color: Color = .blue, isPinned: Bool = false, repeatMode: RepeatMode = .none) {
        self.id = UUID()
        self.title = title
        self.originalDate = Calendar.current.startOfDay(for: targetDate)
        self.colorHex = color.toHex() ?? "#0000FF"
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
        let now = calendar.startOfDay(for: Date())
        let original = calendar.startOfDay(for: originalDate)
        
        if repeatMode == .none {
            return original
        }

        var nextDate = original
        switch repeatMode {
        case .weekly:
            while nextDate < now {
                nextDate = calendar.date(byAdding: .weekOfYear, value: 1, to: nextDate)!
            }
        case .monthly:
            while nextDate < now {
                nextDate = calendar.date(byAdding: .month, value: 1, to: nextDate)!
            }
        case .yearly:
            while nextDate < now {
                nextDate = calendar.date(byAdding: .year, value: 1, to: nextDate)!
            }
        case .none:
            break
        }
        return nextDate
    }

    var daysRemaining: Int {
        let calendar = Calendar.current
        let nowStartOfDay = calendar.startOfDay(for: Date())
        let targetStartOfDay = calendar.startOfDay(for: nextTargetDate)
        let components = calendar.dateComponents([.day], from: nowStartOfDay, to: targetStartOfDay)
        return components.day ?? 0
    }
    
    var daysAbsolute: Int {
        abs(daysRemaining)
    }
    
    var isPast: Bool {
        daysRemaining < 0
    }
    
    var isToday: Bool {
        return daysRemaining == 0
    }
    
    var isExpired: Bool {
        return false;
    }
}
