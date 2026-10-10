// ============================================================
// 📄 EventRow.swift  —  '일정 한 줄' 모양
// ------------------------------------------------------------
// 왼쪽에 시간, 가운데에 제목과 장소, 오른쪽에 알림 종 아이콘을 보여줘요.
// 오늘 화면과 캘린더 화면이 함께 쓰는 부품이에요.
// ============================================================

import SwiftUI

struct EventRow: View {
    let event: CalendarEvent
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity

    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(event.startDate, format: .dateTime.hour().minute())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(ink.opacity(0.72))
                .frame(width: 56, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(ink)
                if !event.location.isEmpty {
                    Label(event.location, systemImage: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundStyle(ink.opacity(0.72))
                }
            }

            Spacer()

            if event.notifyEnabled {
                Image(systemName: "bell.fill")
                    .font(.caption)
                    .foregroundStyle(ink)
            }
        }
    }
}
