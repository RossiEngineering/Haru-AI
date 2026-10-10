// ============================================================
// 📄 AppSettings.swift  —  앱 설정 값의 "이름표"와 AI 동의 기록
// ------------------------------------------------------------
// 설정 화면에서 바꾼 값(브리핑 시간, AI 동의 여부 등)은 폰에 저장돼요.
// 값을 꺼내려면 이름표(key)가 필요한데, 오타를 막으려고 여기 한곳에 모아 뒀어요.
//
// AIConsent: "내 글이 AI 회사로 전송되는 것에 동의했나요?"를 기록해요.
// Apple 심사 규칙상, 동의를 받기 전에는 AI로 아무것도 보내면 안 돼요.
// ============================================================

import SwiftUI

enum AppSettings {
    static let morningEnabledKey = "briefing.morning.enabled"
    static let morningHourKey    = "briefing.morning.hour"
    static let eveningEnabledKey = "briefing.evening.enabled"
    static let eveningHourKey    = "briefing.evening.hour"
    static let aiConsentKey      = "ai.consent.v1"
    static let languageKey       = "app.language"
    static let backgroundKey     = "app.background"
    static let backgroundImageKey = "app.background.image"
    static let textColorKey = "app.appearance.textColor"
    static let textOpacityKey = "app.appearance.textOpacity"
    static let cardColorKey = "app.appearance.cardColor"
    static let cardOpacityKey = "app.appearance.cardOpacity"

    static let defaultBackground = AppBackground.cream.rawValue
    static let defaultTextColor = AppearanceColor.plum.rawValue
    static let defaultTextOpacity = 1.0
    static let defaultCardColor = AppearanceColor.charcoal.rawValue
    static let defaultCardOpacity = 0.05

    private static let appearanceDefaultsVersionKey = "app.appearance.defaults.version"

    /// Apply the fixed appearance once so existing installs also receive the new defaults.
    static func applyAppearanceDefaultsIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.integer(forKey: appearanceDefaultsVersionKey) < 1 else { return }

        defaults.set(defaultBackground, forKey: backgroundKey)
        defaults.set(defaultTextColor, forKey: textColorKey)
        defaults.set(defaultTextOpacity, forKey: textOpacityKey)
        defaults.set(defaultCardColor, forKey: cardColorKey)
        defaults.set(defaultCardOpacity, forKey: cardOpacityKey)
        defaults.removeObject(forKey: backgroundImageKey)
        defaults.set(1, forKey: appearanceDefaultsVersionKey)
    }
}

enum AppearanceColor: String, CaseIterable, Identifiable {
    case charcoal, white, navy, blue, teal, forest, olive, gold, orange, coral, rose, plum, slate
    var id: String { rawValue }
    var title: String {
        switch self {
        case .charcoal: "차콜"
        case .white: "화이트"
        case .navy: "네이비"
        case .blue: "블루"
        case .teal: "청록"
        case .forest: "포레스트"
        case .olive: "올리브"
        case .gold: "골드"
        case .orange: "오렌지"
        case .coral: "코랄"
        case .rose: "로즈"
        case .plum: "플럼"
        case .slate: "슬레이트"
        }
    }
    var color: Color {
        switch self {
        case .charcoal: Color(red: 0.16, green: 0.18, blue: 0.22)
        case .white: Color.white
        case .navy: Color(red: 0.12, green: 0.25, blue: 0.40)
        case .blue: Color(red: 0.20, green: 0.48, blue: 0.82)
        case .teal: Color(red: 0.12, green: 0.58, blue: 0.58)
        case .forest: Color(red: 0.13, green: 0.34, blue: 0.26)
        case .olive: Color(red: 0.46, green: 0.52, blue: 0.20)
        case .gold: Color(red: 0.86, green: 0.65, blue: 0.18)
        case .orange: Color(red: 0.93, green: 0.45, blue: 0.16)
        case .coral: Color(red: 0.92, green: 0.38, blue: 0.36)
        case .rose: Color(red: 0.82, green: 0.36, blue: 0.50)
        case .plum: Color(red: 0.36, green: 0.23, blue: 0.39)
        case .slate: Color(red: 0.30, green: 0.36, blue: 0.44)
        }
    }
}

enum AppLanguage: String, CaseIterable, Identifiable {
    case korean = "ko-KR"
    case english = "en-US"
    var id: String { rawValue }
    var title: String { self == .korean ? "한국어" : "English" }
    var locale: Locale { Locale(identifier: rawValue) }
}

enum AppBackground: String, CaseIterable, Identifiable {
    case system, cream, sky, lavender, mint, rose, photo
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "기본"
        case .cream: "크림"
        case .sky: "하늘"
        case .lavender: "라벤더"
        case .mint: "민트"
        case .rose: "분홍"
        case .photo: "사진"
        }
    }
    var color: Color {
        switch self {
        case .system: Color(.systemBackground)
        case .cream: Color(red: 1.0, green: 0.97, blue: 0.88)
        case .sky: Color(red: 0.87, green: 0.94, blue: 1.0)
        case .lavender: Color(red: 0.94, green: 0.90, blue: 1.0)
        case .mint: Color(red: 0.87, green: 0.97, blue: 0.91)
        case .rose: Color(red: 1.0, green: 0.90, blue: 0.92)
        case .photo: Color(.systemBackground)
        }
    }

    var textColor: Color { Color(red: 0.16, green: 0.19, blue: 0.25) }

    var accentColor: Color {
        switch self {
        case .system: Color.accentColor
        case .photo: Color(red: 0.25, green: 0.34, blue: 0.45)
        case .cream: Color(red: 0.48, green: 0.34, blue: 0.18)
        case .sky: Color(red: 0.16, green: 0.40, blue: 0.62)
        case .lavender: Color(red: 0.42, green: 0.31, blue: 0.60)
        case .mint: Color(red: 0.16, green: 0.45, blue: 0.34)
        case .rose: Color(red: 0.65, green: 0.30, blue: 0.38)
        }
    }

    var rowColor: Color {
        self == .system ? Color(.secondarySystemBackground) : .white.opacity(0.72)
    }
}

struct AppBackgroundLayer: View {
    let background: AppBackground
    let imageData: Data?

    var body: some View {
        GeometryReader { geometry in
            if background == .photo, let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .overlay(Color.white.opacity(0.38))
            } else {
                background.color
            }
        }
        .ignoresSafeArea()
    }
}

enum AIConsent {
    static var isGranted: Bool { UserDefaults.standard.bool(forKey: AppSettings.aiConsentKey) }
    static func grant()  { UserDefaults.standard.set(true, forKey: AppSettings.aiConsentKey) }
    static func revoke() { UserDefaults.standard.removeObject(forKey: AppSettings.aiConsentKey) }
}
