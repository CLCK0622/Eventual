import SwiftUI
import SwiftData

// 定义视图模式
enum ViewMode: String, CaseIterable {
    case list = "列表"
    case grid = "网格"
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    // 基础查询，只按时间排序
    // 更新 Query：使用 originalDate 作为基础排序（虽然我们最终显示的是 nextTargetDate，但用 originalDate 排序通常也够用了，或者你可以不在这里排序，完全在内存中排）
    @Query(sort: \Event.originalDate, order: .forward)
    private var allEvents: [Event]

    // 更新排序和过滤逻辑
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
    // macOS 强制使用网格模式
    private let viewMode: ViewMode = .grid
    #endif

    // 网格布局定义
    private let columns = [
        GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle("Eventual")
                .toolbar {
                    #if os(iOS)
                    // iOS 左侧视图切换按钮
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
                    // 右侧添加按钮
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

    // 使用 @ViewBuilder 根据模式选择视图
    @ViewBuilder
    private var contentView: some View {
        if viewMode == .list {
            // MARK: - 列表视图 (iOS 原生风格)
            List {
                ForEach(sortedEvents) { event in
                    EventRowView(event: event)
                        // 让点击区域覆盖整行
                        .contentShape(Rectangle())
                        .onTapGesture {
                            eventToEdit = event
                        }
                        // iOS 滑动操作
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
            // 使用 .insetGrouped 样式，这是现代 iOS App 最常用的原生列表样式
            // 它会自动处理圆角和背景色，看起来非常原生
            // 仅在 iOS 上使用 insetGrouped 样式
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            // macOS 上使用默认样式，或者 .inset 样式（如果喜欢的话）
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
            // 颜色指示条
            Capsule()
                .fill(Color(hex: event.colorHex) ?? .blue)
                .frame(width: 4, height: 36)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    // 置顶图标
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
                // 修改 1：使用 nextTargetDate 显示正确的下一次日期
                Text(event.nextTargetDate.formatted(date: .numeric, time: event.isAllDay ? .omitted : .shortened))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // 剩余天数 / "就是今天！"
            if event.isToday {
                // 修改 2：如果是今天，显示特殊的高亮文案
                Text("就是今天！")
                    .font(.headline)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
            } else {
                VStack(alignment: .trailing) {
                    Text("\(event.daysRemaining)")
                        .font(.system(.title3, design: .rounded))
                        .bold()
                        // 少于3天变红
                        .foregroundStyle(event.daysRemaining <= 3 && event.daysRemaining >= 0 ? .red : .primary)
                    Text("天")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
