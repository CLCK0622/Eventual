import SwiftUI

struct EventCardView: View {
    let event: Event
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // 1. 背景层
            backgroundLayer
            
            // 2. 渐变遮罩
            LinearGradient(
                colors: [.black.opacity(0.6), .transparent],
                startPoint: .bottom,
                endPoint: .center
            )
            
            // 3. 内容层
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    if event.isToday {
                        // 修改 1：网格卡片上的“就是今天”
                        Text("今天")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                    } else {
                        Text("\(event.daysRemaining)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("天")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.8))
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
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                // 修改 2：使用 nextTargetDate 显示正确的下一次日期
                Text(event.nextTargetDate.formatted(date: .numeric, time: event.isAllDay ? .omitted : .shortened))
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
            }
            .padding(12)
        }
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var backgroundLayer: some View {
        if let data = event.imageData {
            #if os(macOS)
            if let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
            } else { fallbackColor }
            #else
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage).resizable().aspectRatio(contentMode: .fill)
            } else { fallbackColor }
            #endif
        } else {
            fallbackColor
        }
    }
    
    private var fallbackColor: some View {
        Rectangle()
            .fill(Color(hex: event.colorHex)?.gradient ?? Color.blue.gradient)
    }
}

extension Color {
    static let transparent = Color.black.opacity(0)
}
