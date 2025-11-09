import SwiftUI

struct EventCardView: View {
    let event: Event
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundLayer
            
            LinearGradient(colors: [.black.opacity(0.6), .transparent], startPoint: .bottom, endPoint: .center)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    if event.isToday {
                        Text("今天").font(.system(size: 32, weight: .bold, design: .rounded)).foregroundStyle(.white)
                    } else {
                        Text("\(event.daysRemaining)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundStyle(.white)
                        Text("天").font(.caption).fontWeight(.medium).foregroundStyle(.white.opacity(0.8))
                    }
                    Spacer()
                    if event.isPinned { Image(systemName: "pin.fill").foregroundStyle(.yellow).rotationEffect(.degrees(45)) }
                }
                Text(event.title).font(.headline).foregroundStyle(.white).lineLimit(1)
                // 移除时间显示，只显示日期
                Text(event.nextTargetDate.formatted(date: .numeric, time: .omitted))
                    .font(.caption).foregroundStyle(.white.opacity(0.7))
            }
            .padding(12)
        }
        .frame(height: 150)
        // 关键修复：确保整个卡片被裁剪
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous)) // 确保点击区域也正确
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        if let data = event.imageData {
            GeometryReader { geo in
                 #if os(macOS)
                 if let nsImage = NSImage(data: data) {
                     Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
                         .frame(width: geo.size.width, height: geo.size.height) // 强制填满容器
                         .clipped() // 关键修复：裁剪溢出部分
                 } else { fallbackColor }
                 #else
                 if let uiImage = UIImage(data: data) {
                     Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
                         .frame(width: geo.size.width, height: geo.size.height)
                         .clipped()
                 } else { fallbackColor }
                 #endif
            }
        } else {
            fallbackColor
        }
    }
    
    private var fallbackColor: some View {
        Rectangle().fill(Color(hex: event.colorHex)?.gradient ?? Color.blue.gradient)
    }
}

extension Color { static let transparent = Color.black.opacity(0) }
