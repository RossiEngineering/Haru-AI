// ============================================================
// 📄 WeatherType.swift  —  날씨 종류 목록
// ------------------------------------------------------------
// 일기장에서 고를 수 있는 날씨 4가지(맑음/흐림/비/눈)와
// 각 날씨의 이모지·이름을 정해 둔 파일이에요.
// ============================================================

import Foundation

enum WeatherType: String, CaseIterable, Identifiable {
    case sunny, cloudy, rainy, snowy

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .sunny:  return "☀️"
        case .cloudy: return "☁️"
        case .rainy:  return "🌧️"
        case .snowy:  return "❄️"
        }
    }

    var label: String {
        switch self {
        case .sunny:  return "맑음"
        case .cloudy: return "흐림"
        case .rainy:  return "비"
        case .snowy:  return "눈"
        }
    }
}
