// ============================================================
// 📄 AIAction.swift  —  AI가 알려주는 "할 일 지시서"
// ============================================================

import Foundation

struct AIAction: Decodable {
    let type: String
    let title: String?
    let start: String?
    let location: String?
    let reply: String

    static func parseDate(_ string: String?) -> Date? {
        guard let string else { return nil }

        if let date = ISO8601DateFormatter().date(from: string) {
            return date
        }

        let fallback = DateFormatter()
        fallback.locale = Locale(identifier: "en_US_POSIX")
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        fallback.timeZone = .current
        return fallback.date(from: string)
    }
}
