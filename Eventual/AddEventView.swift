import SwiftUI
import SwiftData
import PhotosUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var eventToEdit: Event? = nil

    @State private var title: String = ""
    @State private var targetDate: Date = Date()
    @State private var selectedColor: Color = .blue
    @State private var isAllDay: Bool = true
    @State private var isPinned: Bool = false
    @State private var notes: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil
    // 新增：重复模式状态
    @State private var repeatMode: RepeatMode = .none

    // 计算属性：判断日期是否有效（一次性事件必须是未来）
    var isDateValid: Bool {
        if repeatMode == .none {
            // 如果是一次性事件，所选日期必须 >= 今天
            return Calendar.current.startOfDay(for: targetDate) >= Calendar.current.startOfDay(for: Date())
        }
        return true // 重复性事件可以选择过去的基准日期（如出生日期）
    }

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle(eventToEdit == nil ? "添加新事件" : "编辑事件")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("取消") { dismiss() }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") { saveEvent() }
                            // 只有标题不为空且日期有效时，才能保存
                            .disabled(title.isEmpty || !isDateValid)
                    }
                }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: loadData)
        .onChange(of: selectedPhotoItem, loadPhoto)
        // 监听重复模式变化，如果变为一次性，强制设为全天（根据你的需求可调整）
        .onChange(of: repeatMode) {
             if repeatMode == .none {
                 isAllDay = true
             }
        }
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(macOS)
        macOSLayout.frame(minWidth: 500, minHeight: 450).padding()
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS 布局
    #if os(macOS)
    @ViewBuilder
    private var macOSLayout: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("基本信息").font(.headline).foregroundStyle(.secondary)
                    TextField("事件标题", text: $title).textFieldStyle(.roundedBorder).font(.title3)
                    
                    // 新增：重复模式选择器
                    Picker("重复", selection: $repeatMode) {
                        ForEach(RepeatMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        DatePicker("日期", selection: $targetDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                            .labelsHidden()
                        // 只有非一次性事件才允许切换全天状态，或者你可以随时允许
                        Toggle("全天", isOn: $isAllDay)
                            .toggleStyle(.button)
                            // 如果你希望一次性事件强制全天，可以禁用这个 Toggle
                             .disabled(repeatMode == .none)
                    }
                    if !isDateValid {
                        Text("一次性事件必须选择未来的日期")
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                Divider()
                // ... (外观与设置部分保持不变)
                VStack(alignment: .leading, spacing: 8) {
                     Text("外观与设置").font(.headline).foregroundStyle(.secondary)
                     HStack {
                         ColorPicker("主题色", selection: $selectedColor, supportsOpacity: false).labelsHidden()
                         Text("主题色")
                         Spacer()
                         Toggle("置顶", isOn: $isPinned).toggleStyle(.switch)
                     }
                 }
                Divider()
                // ... (备注部分保持不变)
                 VStack(alignment: .leading, spacing: 8) {
                     Text("备注").font(.headline).foregroundStyle(.secondary)
                     TextEditor(text: $notes).font(.body).frame(height: 80).padding(4).background(Color(nsColor: .textBackgroundColor)).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                 }
            }
            .frame(maxWidth: .infinity)
            // ... (右侧图片部分保持不变，直接复用之前的代码)
             VStack(alignment: .center, spacing: 12) {
                 Text("背景图片").font(.headline).foregroundStyle(.secondary)
                 ZStack {
                     RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5])).frame(height: 200)
                     if let data = selectedImageData, let nsImage = NSImage(data: data) { Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill).frame(height: 200).clipShape(RoundedRectangle(cornerRadius: 12)) } else { VStack(spacing: 8) { Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(.secondary); Text("点击选择").font(.caption).foregroundStyle(.secondary) } }
                 }
                 .onTapGesture { /* macOS 点击逻辑需完善，暂时依赖下方按钮 */ }
                 HStack {
                     if selectedImageData != nil { Button("清除", role: .destructive) { withAnimation { selectedImageData = nil; selectedPhotoItem = nil } } }
                     PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) { Text(selectedImageData == nil ? "选择图片..." : "更换") }
                 }
             }.frame(width: 220)
        }
    }
    #endif

    // MARK: - iOS 布局
    #if os(iOS)
    @ViewBuilder
    private var iOSLayout: some View {
        Form {
            Section("基本信息") {
                TextField("标题", text: $title)
                Picker("重复", selection: $repeatMode) {
                    ForEach(RepeatMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
            }
            Section("日期和时间") {
                Toggle("全天事件", isOn: $isAllDay.animation())
                    // 如果你希望一次性事件强制全天，可以禁用
                    .disabled(repeatMode == .none)
                
                DatePicker("目标日期", selection: $targetDate, displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
                
                if !isDateValid {
                    Text("一次性事件必须选择未来的日期")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("外观") {
                ColorPicker("主题色", selection: $selectedColor, supportsOpacity: false)
                Toggle("置顶", isOn: $isPinned)
            }
            // ... (背景图片和备注部分保持不变，直接复用之前的代码)
            Section("背景图片") {
                 PhotosPicker(selection: $selectedPhotoItem, matching: .images, photoLibrary: .shared()) {
                     HStack { Text("选择图片"); Spacer(); if let data = selectedImageData, let uiImage = UIImage(data: data) { Image(uiImage: uiImage).resizable().scaledToFill().frame(width: 40, height: 40).clipShape(RoundedRectangle(cornerRadius: 8)) } else { Image(systemName: "photo").foregroundStyle(.secondary) } }
                 }
                 if selectedImageData != nil { Button("清除图片", role: .destructive) { withAnimation { selectedImageData = nil; selectedPhotoItem = nil } } }
             }
             Section("备注") { TextField("写点什么...", text: $notes, axis: .vertical).lineLimit(3...6) }
        }
    }
    #endif

    // MARK: - 逻辑方法
    private func loadData() {
        if let event = eventToEdit {
            title = event.title
            // 注意这里加载的是 originalDate
            targetDate = event.originalDate
            selectedColor = Color(hex: event.colorHex) ?? .blue
            isAllDay = event.isAllDay
            isPinned = event.isPinned
            notes = event.notes ?? ""
            selectedImageData = event.imageData
            repeatMode = event.repeatMode
        } else {
            // 新建事件默认设置为明天
            targetDate = Date().addingTimeInterval(86400)
        }
    }
    
    // ... (loadPhoto 保持不变)
    private func loadPhoto() { Task { if let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) { selectedImageData = data } } }

    private func saveEvent() {
        guard !title.isEmpty && isDateValid else { return }
        if let event = eventToEdit {
            event.title = title
            event.originalDate = targetDate // 更新 originalDate
            event.colorHex = selectedColor.toHex() ?? "#0000FF"
            event.isAllDay = isAllDay
            event.isPinned = isPinned
            event.notes = notes.isEmpty ? nil : notes
            event.imageData = selectedImageData
            event.repeatMode = repeatMode
        } else {
            let newEvent = Event(title: title, targetDate: targetDate, color: selectedColor, isAllDay: isAllDay, isPinned: isPinned, repeatMode: repeatMode)
            newEvent.notes = notes.isEmpty ? nil : notes
            newEvent.imageData = selectedImageData
            modelContext.insert(newEvent)
        }
        dismiss()
    }
}
