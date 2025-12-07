import SwiftData
import SwiftUI

enum RepeatMode: String, CaseIterable, Codable {
    case none = "None"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"
    
    var localizedName: LocalizedStringResource {
        switch self {
        case .none: return "一次性"
        case .weekly: return "每周"
        case .monthly: return "每月"
        case .yearly: return "每年"
        }
    }
}

@Model
class Event {
    var id: UUID = UUID()
    var title: String = ""
    var originalDate: Date = Date()
    var colorHex: String = "#0000FF"
    var notes: String?
    var createdAt: Date = Date()
    var isPinned: Bool = false
    
    var imageData: Data?
    
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
        daysRemaining == 0
    }
    
    var isExpired: Bool {
        return false
    }
}
