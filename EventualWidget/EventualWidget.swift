import WidgetKit
import SwiftUI
import SwiftData

struct Provider: AppIntentTimelineProvider {
    static let modelContainer: ModelContainer? = try? SharedModelContainer.create()

    @MainActor
    private func fetchEvent(for configuration: ConfigurationAppIntent) -> Event? {
        guard let container = Provider.modelContainer else { return nil }
        let context = container.mainContext
        
        // 1. 如果用户选择了特定事件
        if let selectedEntity = configuration.event {
            var descriptor = FetchDescriptor<Event>()
            if let allEvents = try? context.fetch(descriptor) {
                return allEvents.first(where: { $0.id == selectedEntity.id })
            }
        }
        
        // 2. 默认逻辑：获取最近的重要事件
        var descriptor = FetchDescriptor<Event>()
        if let allEvents = try? context.fetch(descriptor), !allEvents.isEmpty {
             return allEvents
                 .filter { !$0.isExpired }
                 .sorted {
                     if $0.isPinned != $1.isPinned { return $0.isPinned && !$1.isPinned }
                     return $0.nextTargetDate < $1.nextTargetDate
                 }
                 .first
         }
        
        return nil
    }

    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), event: Event(title: "示例事件", targetDate: Date(), color: .blue))
    }

    @MainActor
    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        let event = fetchEvent(for: configuration)
        return SimpleEntry(date: Date(), event: event)
    }

    @MainActor
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let event = fetchEvent(for: configuration)
        let entry = SimpleEntry(date: Date(), event: event)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let event: Event?
}

struct EventualWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        GeometryReader { geo in
            if let event = entry.event {
                ZStack(alignment: .bottomLeading) {
                    backgroundLayer(for: event)
                        .frame(width: geo.size.width, height: geo.size.height)
                        .clipped()
                    LinearGradient(colors: [.black.opacity(0.6), .clear], startPoint: .bottom, endPoint: .top)
                    contentLayer(for: event)
                        .padding(family == .systemSmall ? 12 : 16)
                }
                .widgetURL(URL(string: "eventual://open/\(event.id)"))
            } else {
                emptyStateView
            }
        }
    }
    
    @ViewBuilder
    private func backgroundLayer(for event: Event) -> some View {
        // 调试点：确认 imageData 是否有值
        if let data = event.imageData {
            #if os(macOS)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                colorBackground(for: event)
            }
            #else
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                colorBackground(for: event)
            }
            #endif
        } else {
            colorBackground(for: event)
        }
    }
    
    private func colorBackground(for event: Event) -> some View {
        Rectangle().fill(Color(hex: event.colorHex)?.gradient ?? Color.blue.gradient)
    }
    
    private func contentLayer(for event: Event) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline) {
                if event.isToday {
                     Text("今天")
                         .font(.system(size: family == .systemSmall ? 28 : 34, weight: .heavy, design: .rounded))
                         .foregroundStyle(.white)
                 } else {
                     Text("\(event.daysRemaining)")
                         .font(.system(size: family == .systemSmall ? 38 : 48, weight: .heavy, design: .rounded))
                         .foregroundStyle(.white)
                     Text("天")
                         .font(.subheadline.bold())
                         .foregroundStyle(.white.opacity(0.9))
                 }
                Spacer()
                if event.isPinned {
                    Image(systemName: "pin.fill")
                        .foregroundStyle(.yellow)
                        .rotationEffect(.degrees(45))
                }
            }
            Text(event.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .lineLimit(1)
            Text(event.nextTargetDate.formatted(date: .numeric, time: .omitted))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.8))
        }
    }
    
    private var emptyStateView: some View {
        VStack {
            Text("暂无事件").font(.headline).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.gray.opacity(0.1))
    }
}

struct EventualWidget: Widget {
    let kind: String = "EventualWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: Provider()) { entry in
            if #available(iOS 17.0, macOS 14.0, *) {
                EventualWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) { Color.clear }
            } else {
                EventualWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("倒数日")
        .description("追踪你最重要的日子。")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
        .contentMarginsDisabled()
    }
}
