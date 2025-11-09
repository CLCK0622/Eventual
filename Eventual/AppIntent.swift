import AppIntents
import SwiftData
import SwiftUI

struct EventEntity: AppEntity {
    static var defaultQuery = EventQuery()
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "事件"

    var id: UUID
    @Property(title: "标题") var title: String

    init(id: UUID, title: String) {
        self.id = id
        self.title = title
    }

    init(from event: Event) {
        self.id = event.id
        self.title = event.title
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(title)")
    }
}

struct EventQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [UUID]) async throws -> [EventEntity] {
        let modelContainer = SharedModelContainer.create()
        let modelContext = modelContainer.mainContext
        var descriptor = FetchDescriptor<Event>()
        
        if let allEvents = try? modelContext.fetch(descriptor) {
            return allEvents
                .filter { identifiers.contains($0.id) }
                .map { EventEntity(from: $0) }
        }
        return []
    }

    @MainActor
    func suggestedEntities() async throws -> [EventEntity] {
        let modelContainer = SharedModelContainer.create()
        let modelContext = modelContainer.mainContext
        var descriptor = FetchDescriptor<Event>()
        
        if let allEvents = try? modelContext.fetch(descriptor) {
            return allEvents
                .filter { !$0.isExpired }
                .sorted {
                    if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
                    return $0.nextTargetDate < $1.nextTargetDate
                }
                .map { EventEntity(from: $0) }
        }
        return []
    }
    
    @MainActor
    func defaultResult() async -> EventEntity? {
        try? await suggestedEntities().first
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "选择事件"
    static var description: IntentDescription = "选择要在小组件中显示的特定事件。"

    @Parameter(title: "事件")
    var event: EventEntity?
}
