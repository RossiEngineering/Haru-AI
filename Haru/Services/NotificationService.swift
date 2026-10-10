// ============================================================
// 📄 NotificationService.swift  —  일정 알림 담당
// ------------------------------------------------------------
// 일정을 저장할 때 "일정 10분 전에 알려줘"라고 폰에 예약하거나,
// 일정을 지울 때 예약을 취소하는 일을 해요.
// (아침 브리핑·저녁 일기 알림은 BriefingService가 따로 담당해요)
// ============================================================

import Foundation
import UserNotifications

enum NotificationService {

    /// 앱을 처음 켤 때 "알림을 보내도 될까요?" 하고 허락을 물어봐요.
    static func requestPermission() async {
        _ = try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    /// 일정 시작 10분 전에 울리도록 예약해요. (일정을 고치면 다시 예약돼요)
    static func schedule(for event: CalendarEvent) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [event.notificationID])

        // 알림을 끈 일정이거나 이미 지난 일정이면 예약하지 않아요.
        guard event.notifyEnabled, event.startDate > .now else { return }

        let content = UNMutableNotificationContent()
        content.title = event.title
        content.body = event.location.isEmpty ? "곧 일정이 시작돼요" : "📍 \(event.location)"
        content.sound = .default

        // 10분 전. 이미 10분 안쪽이면 5초 뒤에 바로 알려줘요.
        let fireDate = max(event.startDate.addingTimeInterval(-600), Date().addingTimeInterval(5))
        let parts = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)

        center.add(UNNotificationRequest(identifier: event.notificationID,
                                         content: content,
                                         trigger: trigger))
    }

    /// 일정을 지울 때 예약된 알림도 같이 취소해요.
    static func cancel(for event: CalendarEvent) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [event.notificationID])
    }

    /// 계정을 삭제할 때 예약된 알림을 전부 지워요.
    static func cancelAll() {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}
