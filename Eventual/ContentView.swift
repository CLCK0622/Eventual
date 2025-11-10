import SwiftUI
import SwiftData

// 定义视图模式
enum ViewMode: String, CaseIterable {
    case list = "列表"
    case grid = "网格"
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
                                    Label(mode.rawValue, systemImage: mode == .list ? "list.bullet" : "square.grid.2x2")
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
            // MARK: - 列表视图 (iOS 原生风格)
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
                                Label(event.isPinned ? "取消置顶" : "置顶", systemImage: event.isPinned ? "pin.slash.fill" : "pin.fill")
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
            // MARK: - 网格视图 (macOS & iOS)
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(sortedEvents) { event in
                        EventCardView(event: event)
                            .onTapGesture { eventToEdit = event }
                            .contextMenu {
                                Button { togglePin(event) } label: {
                                    Label(event.isPinned ? "取消置顶" : "置顶", systemImage: event.isPinned ? "pin.slash.fill" : "pin.fill")
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
    }

    private func deleteEvent(_ event: Event) {
        withAnimation {
            modelContext.delete(event)
        }
    }
}

// MARK: - 简化的行视图
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
                            .foregroundStyle(.orange)
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
                Text("就是今天！")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(alignment: .trailing) {
                    Text("\(event.daysAbsolute)")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        .foregroundStyle(!event.isPast && event.daysRemaining <= 3 ? .red : .primary)
                    
                    Text(event.isPast ? "已经" : "还有")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
