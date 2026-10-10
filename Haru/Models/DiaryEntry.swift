// ============================================================
// 📄 DiaryEntry.swift  —  '일기 한 편'의 설계도
// ------------------------------------------------------------
// 일기 = 날짜 + 날씨 + 오늘 하루 글 + 사진(선택)
// ============================================================

import Foundation
import SwiftData

@Model
final class DiaryEntry {
    var date: Date                 // 일기 날짜
    var weatherRaw: String         // 날씨를 글자로 저장 (예: "sunny")
    var content: String            // 오늘 하루 적은 글

    // 사진은 용량이 커서 따로 파일로 저장하도록 표시해요.
    @Attribute(.externalStorage) var photoData: Data?

    // 저장은 글자("sunny")로 하고, 쓸 때는 WeatherType으로 편하게 바꿔 써요.
    var weather: WeatherType {
        get { WeatherType(rawValue: weatherRaw) ?? .sunny }
        set { weatherRaw = newValue.rawValue }
    }

    init(date: Date = .now,
         weather: WeatherType = .sunny,
         content: String = "",
         photoData: Data? = nil) {
        self.date = date
        self.weatherRaw = weather.rawValue
        self.content = content
        self.photoData = photoData
    }
}
