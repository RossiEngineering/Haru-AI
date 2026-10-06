// ============================================================
// 📄 HaruApp.swift  —  앱의 "현관문"
// ------------------------------------------------------------
// 앱을 실행하면 가장 먼저 읽히는 파일이에요.
// ============================================================

import SwiftUI
import SwiftData

@main
struct HaruApp: App {
    @State private var auth = AuthService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(auth)
        }
        .modelContainer(for: [CalendarEvent.self, TodoItem.self, DiaryEntry.self])
    }
}
