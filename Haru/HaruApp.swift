// ============================================================
// 📄 HaruApp.swift  —  앱의 "현관문"
// ------------------------------------------------------------
// 앱을 실행하면 가장 먼저 읽히는 파일이에요.
// 여기서 세 가지를 준비해요.
//   1) 로그인 상태를 관리하는 AuthService 만들기
//   2) 일정 · 할 일 · 일기를 저장할 저장소(SwiftData) 연결하기
//   3) 앱이 열려 있을 때도 알림 배너가 보이도록 설정하기
// 준비가 끝나면 RootView(로그인 여부에 따라 화면을 고르는 파일)를 보여줘요.
// ============================================================

import SwiftUI
import SwiftData
import UserNotifications

@main
struct HaruApp: App {
    // 로그인 정보를 앱 전체가 함께 쓰도록 하나만 만들어 둬요.
    @State private var auth = AuthService()

    init() {
        AppSettings.applyAppearanceDefaultsIfNeeded()
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)   // 모든 화면에서 auth를 꺼내 쓸 수 있게 해줘요
        }
        // 이 3가지 데이터를 폰 안에 저장해요. (앱을 꺼도 사라지지 않아요)
        .modelContainer(for: [CalendarEvent.self, TodoItem.self, DiaryEntry.self])
    }
}
