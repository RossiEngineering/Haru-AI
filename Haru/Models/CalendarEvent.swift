// ============================================================
// 📄 CalendarEvent.swift  —  '일정' 하나의 설계도
// ------------------------------------------------------------
// 일정 하나가 어떤 정보를 가지는지 정해 둔 파일이에요.
// 일정 = 제목 + 시작/종료 시간 + 장소 + 메모 + 알림을 줄지 여부
// @Model 이라고 적으면 SwiftData가 이 정보를 폰에 저장해 줘요.
// ============================================================

import Foundation
import SwiftData

@Model
final class CalendarEvent {
    var title: String          // 무엇을 하나요? (예: 치과 예약)
    var startDate: Date        // 시작 시간
    var endDate: Date          // 종료 시간
    var location: String       // 장소 (비워도 돼요)
    var memo: String           // 메모
    var notifyEnabled: Bool    // true = 알림을 줘요, false = 알림 없음
    var notificationID: String // 알림을 취소할 때 쓰는 이름표

    init(title: String,
         startDate: Date,
         endDate: Date? = nil,
         location: String = "",
         memo: String = "",
         notifyEnabled: Bool = true) {
        self.title = title
        self.startDate = startDate
        // 종료 시간을 안 정하면 1시간짜리 일정으로 만들어요.
        self.endDate = endDate ?? startDate.addingTimeInterval(3600)
        self.location = location
        self.memo = memo
        self.notifyEnabled = notifyEnabled
        self.notificationID = UUID().uuidString
    }
}
