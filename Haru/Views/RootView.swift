// ============================================================
// 📄 RootView.swift  —  "로그인했나요?" 문지기
// ------------------------------------------------------------
// 로그인한 사람은 메인 화면(MainTabView)으로,
// 아직 로그인 안 한 사람은 로그인 화면(LoginView)으로 보내줘요.
// ============================================================

import SwiftUI

struct RootView: View {
    @Environment(AuthService.self) private var auth
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity

    var body: some View {
        Group {
            if auth.isLoggedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
        .foregroundStyle((AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity))
    }
}
