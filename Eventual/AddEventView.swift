import SwiftUI
import WidgetKit
import SwiftData
import PhotosUI

struct AddEventView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var eventToEdit: Event? = nil

    @State private var title: String = ""
    @State private var targetDate: Date = Date().addingTimeInterval(86400)
    @State private var selectedColor: Color = .blue
    @State private var isPinned: Bool = false
    @State private var repeatMode: RepeatMode = .none
    @State private var notes: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var selectedImageData: Data? = nil

    var body: some View {
        NavigationStack {
            contentView
                .navigationTitle(eventToEdit == nil ? "添加新事件" : "编辑事件")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("取消") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button("保存") { saveEvent() }.disabled(title.isEmpty) }
                }
        }
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear(perform: loadData)
        .onChange(of: selectedPhotoItem, loadPhoto)
    }

    @ViewBuilder
    private var contentView: some View {
        #if os(macOS)
        macOSLayout.frame(minWidth: 600, minHeight: 300).padding()
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
                    Picker("重复", selection: $repeatMode) {
                        ForEach(RepeatMode.allCases, id: \.self) { mode in Text(mode.rawValue).tag(mode) }
                    }.pickerStyle(.segmented)
                    
                    DatePicker("日期", selection: $targetDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                }
                Divider()
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
                 VStack(alignment: .leading, spacing: 8) {
                     Text("备注").font(.headline).foregroundStyle(.secondary)
                     TextEditor(text: $notes).font(.body).frame(height: 80).padding(4).background(Color(nsColor: .textBackgroundColor)).cornerRadius(6).overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                 }
            }
            .frame(maxWidth: .infinity)

             VStack(alignment: .center, spacing: 12) {
                 Text("背景图片").font(.headline).foregroundStyle(.secondary)
                 ZStack {
                     RoundedRectangle(cornerRadius: 12).fill(Color.gray.opacity(0.1)).stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: 2, dash: [5])).frame(height: 200)
                     if let data = selectedImageData, let nsImage = NSImage(data: data) {
                         Image(nsImage: nsImage)
                             .resizable()
                             .aspectRatio(contentMode: .fill)
                             .frame(width: 220, height: 200)
                             .clipShape(RoundedRectangle(cornerRadius: 12))
                     } else {
                         VStack(spacing: 8) { Image(systemName: "photo.badge.plus").font(.system(size: 40)).foregroundStyle(.secondary); Text("点击选择").font(.caption).foregroundStyle(.secondary) }
                     }
                 }
                 .onTapGesture{}
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
                    ForEach(RepeatMode.allCases, id: \.self) { mode in Text(mode.rawValue).tag(mode) }
                }
            }
            Section("日期") {
                DatePicker("目标日期", selection: $targetDate, displayedComponents: .date)
            }
            Section("外观") {
                ColorPicker("主题色", selection: $selectedColor, supportsOpacity: false)
                Toggle("置顶", isOn: $isPinned)
            }
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

    private func loadData() {
        if let event = eventToEdit {
            title = event.title
            targetDate = event.originalDate
            selectedColor = Color(hex: event.colorHex) ?? .blue
            isPinned = event.isPinned
            notes = event.notes ?? ""
            selectedImageData = event.imageData
            repeatMode = event.repeatMode
        } else {
            targetDate = Date().addingTimeInterval(86400)
        }
    }
    
    private func loadPhoto() {
        Task {
            guard let data = try? await selectedPhotoItem?.loadTransferable(type: Data.self) else { return }
            
            guard let originalImage = PlatformImage(data: data) else { return }
            
            if let resizedImage = originalImage.resized(toMaxDimension: 1024) {
                if let resizedData = resizedImage.toJpegData(compressionQuality: 0.7) {
                    selectedImageData = resizedData
                } else {
                    selectedImageData = data
                }
            } else {
                selectedImageData = data
            }
        }
    }

    private func saveEvent() {
        guard !title.isEmpty else { return }
        let cleanDate = Calendar.current.startOfDay(for: targetDate)
        
        if let event = eventToEdit {
            event.title = title
            event.originalDate = cleanDate
            event.colorHex = selectedColor.toHex() ?? "#0000FF"
            event.isPinned = isPinned
            event.notes = notes.isEmpty ? nil : notes
            event.imageData = selectedImageData
            event.repeatMode = repeatMode
        } else {
            let newEvent = Event(title: title, targetDate: cleanDate, color: selectedColor, isPinned: isPinned, repeatMode: repeatMode)
            newEvent.notes = notes.isEmpty ? nil : notes
            newEvent.imageData = selectedImageData
            modelContext.insert(newEvent)
        }
        WidgetCenter.shared.reloadAllTimelines()
        dismiss()
    }
}
