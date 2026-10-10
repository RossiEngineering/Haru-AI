// ============================================================
// 📄 NotificationDelegate.swift  —  앱을 켜 둔 상태에서도 알림 보여주기
// ------------------------------------------------------------
// 아이폰은 기본적으로 '앱이 열려 있는 동안'에는 알림 배너를 숨겨요.
// 그러면 "알림을 설정했는데 안 울려요"처럼 느껴질 수 있어서,
// 앱이 열려 있어도 배너와 소리로 알려주도록 허락해 주는 파일이에요.
// ============================================================

import UserNotifications

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}
