import SwiftUI
import WidgetKit
import SwiftData

enum ViewMode: String, CaseIterable {
    case list = "List"
    case grid = "Grid"
    
    var localizedName: LocalizedStringKey {
        switch self {
        case .list: return "列表"
        case .grid: return "网格"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Event.originalDate, order: .forward)
    private var allEvents: [Event]

    var sortedEvents: [Event] {
        let activeEvents = allEvents.filter { !$0.isExpired }
        let dateSorted = activeEvents.sorted { $0.nextTargetDate < $1.nextTargetDate }
        let pinned = dateSorted.filter { $0.isPinned }
        let unpinned = dateSorted.filter { !$0.isPinned }
        return pinned + unpinned
    }

    @State private var showingAddSheet = false
    @State private var eventToEdit: Event? = nil
    
    #if os(iOS)
    @AppStorage("viewMode") private var viewMode: ViewMode = .list
    #else
    private let viewMode: ViewMode = .grid
    #endif

    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Eventual")
                .toolbar {
                    #if os(iOS)
                    ToolbarItem(placement: .topBarLeading) {
                        Menu {
                            Picker("视图模式", selection: $viewMode) {
                                ForEach(ViewMode.allCases, id: \.self) { mode in
                                    Label(mode.localizedName, systemImage: mode == .list ? "list.bullet" : "square.grid.2x2")
                                        .tag(mode)
                                }
                            }
                        } label: {
                            Image(systemName: viewMode == .list ? "list.bullet" : "square.grid.2x2")
                        }
                    }
                    #endif
                    ToolbarItem(placement: .primaryAction) {
                        Button(action: { showingAddSheet.toggle() }) {
                            Label("添加", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddEventView()
                }
                .sheet(item: $eventToEdit) { event in
                    AddEventView(eventToEdit: event)
                }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if viewMode == .list {
            List {
                ForEach(sortedEvents) { event in
                    EventRowView(event: event)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            eventToEdit = event
                        }
                        #if os(iOS)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) { deleteEvent(event) } label: {
                                Label("删除", systemImage: "trash")
                            }
                        }
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Button { togglePin(event) } label: {
                                Label(event.isPinned ? LocalizedStringKey("取消置顶") : LocalizedStringKey("置顶"), systemImage: event.isPinned ? "pin.slash.fill" : "pin.fill")
                            }
                            .tint(.orange)
                        }
                        #endif
                }
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.inset)
            #endif
        } else {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sortedEvents) { event in
                        EventCardView(event: event)
                            .onTapGesture { eventToEdit = event }
                            .contextMenu {
                                Button { togglePin(event) } label: {
                                    Label(event.isPinned ? LocalizedStringKey("取消置顶") : LocalizedStringKey("置顶"), systemImage: event.isPinned ? "pin.slash.fill" : "pin.fill")
                                }
                                Divider()
                                Button(role: .destructive) { deleteEvent(event) } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                    }
                }
                .padding()
            }
        }
    }

    private func togglePin(_ event: Event) {
        event.isPinned.toggle()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func deleteEvent(_ event: Event) {
        withAnimation {
            modelContext.delete(event)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }
}

struct EventRowView: View {
    let event: Event
    
    var body: some View {
        HStack {
            Capsule()
                .fill(Color(hex: event.colorHex) ?? .blue)
                .frame(width: 4, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    if event.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(45))
                    }
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)
                }
                Text(event.nextTargetDate.formatted(date: .numeric, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if event.isToday {
                Text(LocalizedStringKey("就是今天！"))
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(event.isPast ? LocalizedStringKey("已经") : LocalizedStringKey("还有"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Text("\(event.daysAbsolute)")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundStyle(!event.isPast && event.daysRemaining <= 3 ? .red : .primary)
                    
                    Text(LocalizedStringKey("天"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
