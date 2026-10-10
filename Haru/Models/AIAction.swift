// ============================================================
// 📄 AIAction.swift  —  AI가 돌려주는 "할 일 지시서"의 모양
// ------------------------------------------------------------
// 사용자가 "내일 3시에 치과, 금요일까지 보고서 제출"이라고 말하면
// AI는 아래처럼 정리해서 답해줘요.
//   reply : 사용자에게 보여줄 한마디
//   items : 찾아낸 일정/할 일 목록 (여러 개 가능!)
//     type: "event"(일정) 또는 "todo"(할 일)
// 앱은 이 목록을 '확인 카드'로 먼저 보여주고, 사용자가 허락해야 저장해요.
// ============================================================

import Foundation

struct AIReply: Decodable {
    let reply: String
    let items: [AIItem]

    enum CodingKeys: String, CodingKey { case reply, items }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reply = try container.decode(String.self, forKey: .reply)
        // AI가 items를 빠뜨려도 '그냥 대화'로 취급해요.
        items = try container.decodeIfPresent([AIItem].self, forKey: .items) ?? []
    }
}

struct AIItem: Decodable {
    let type: String
    let title: String?
    let start: String?
    let location: String?

    var isEvent: Bool { type == "event" }
    var isTodo: Bool { type == "todo" }
    var startDate: Date? { AIItem.parseDate(start) }

    /// "2026-10-05T15:00:00+09:00" 같은 글자를 진짜 날짜(Date)로 바꿔줘요.
    static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }

        // 1순위: 시간대(+09:00)까지 정확히 적힌 형태
        if let date = ISO8601DateFormatter().date(from: string) { return date }

        // 2순위: 시간대 없이 적혀 있으면 내 폰의 시간대로 해석
        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fallback.timeZone = .current
        return fallback.date(from: string)
    }
}
