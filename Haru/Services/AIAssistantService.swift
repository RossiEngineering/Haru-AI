// ============================================================
// 📄 AIAssistantService.swift  —  AI 비서(Google Gemini)와 대화하는 담당
// ------------------------------------------------------------
// 하는 일 두 가지
//  1) parseCommand : "내일 3시 치과, 금요일까지 보고서" → 일정/할 일 목록으로 정리
//  2) draftDiary   : 오늘 한 일·일정·날씨로 일기 초안 쓰기
//
// 안전장치
//  · 사용자가 '동의'하기 전에는 아무것도 보내지 않아요 (AIConsent)
//  · 서버 주소(AppConfig.aiProxyURL)가 있으면 서버로 보내요. → 앱에 API 키가 없어도 돼요.
//  · 서버가 없으면 Debug(내가 Xcode로 직접 실행)에서만 환경 변수의 키를 써요.
//    Release(앱스토어/TestFlight) 빌드에서는 키를 쓰는 코드가 아예 빠져요.
//  · Gemini가 잠깐 바쁠 때(429·500·502·503·504)는 잠시 기다렸다가 최대 3번까지 다시 시도해요.
//
// 서버가 지켜야 할 약속: 앱이 보낸 JSON을 받아서 API 키를 붙여 Gemini의
// generateContent에 전달하고, 받은 응답을 그대로 돌려줄 것.
// ============================================================

import Foundation

struct AIAssistantService {

    // 사용자에게 보여줄 오류 문구들
    enum AIError: LocalizedError {
        case consentRequired
        case missingKey
        case notConfigured
        case server(Int, String?)
        case unreadable

        var errorDescription: String? {
            switch self {
            case .consentRequired:
                return "AI 기능을 쓰려면 데이터 전송에 동의해 주세요."
            case .missingKey:
                return "API 키가 비어 있어요. Xcode 실행 Scheme에 GEMINI_API_KEY를 설정해 주세요."
            case .notConfigured:
                return "AI 서버 주소가 아직 설정되지 않았어요."
            case .server(let code, let detail):
                switch code {
                case 401, 403:
                    return "API 키가 올바르지 않거나 권한이 없어요 (코드 \(code)). Gemini 키와 사용 권한을 확인해 주세요."
                case 429, 500, 502, 503, 504:
                    return "AI 서버가 지금 바빠요. 잠시 후 다시 시도해 주세요 (코드 \(code))."
                default:
                    let extra = detail.map { "\n\($0)" } ?? ""
                    return "AI 서버에서 오류가 났어요 (코드 \(code)).\(extra)"
                }
            case .unreadable:
                return "AI의 답을 이해하지 못했어요. 한 번만 더 시도해 주세요."
            }
        }
    }

    // 잠깐 바쁠 때 다시 시도할 오류 번호들
    private let retryableCodes: Set<Int> = [429, 500, 502, 503, 504]
    private let maxAttempts = 3

    // Gemini가 돌려주는 답의 모양
    private struct GeminiResponse: Decodable {
        struct Candidate: Decodable {
            struct Content: Decodable {
                struct Part: Decodable { let text: String? }
                let parts: [Part]?
            }
            let content: Content?
        }
        let candidates: [Candidate]?
    }

    // Gemini가 오류일 때 돌려주는 설명의 모양
    private struct GeminiErrorBody: Decodable {
        struct Detail: Decodable { let message: String? }
        let error: Detail?
    }

    // MARK: - 1) 말 → 일정/할 일 목록

    func parseCommand(_ userText: String) async throws -> AIReply {
        // 지금 시각을 알려줘야 AI가 "내일", "다음 주 화요일"을 계산할 수 있어요.
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        let now = formatter.string(from: .now)

        let system = """
        너는 '하루' 일정 관리 앱 안의 비서야.
        현재 시각: \(now) (시간대: \(TimeZone.current.identifier))

        사용자의 말에서 일정과 할 일을 '모두' 찾아 아래 형식의 JSON 객체 '하나만' 출력해.
        JSON 밖의 글자, 설명, 코드블록(```)은 절대 쓰지 마.

        {
          "reply": "사용자에게 보여줄 친절한 한국어 한두 문장",
          "items": [
            {
              "type": "event" 또는 "todo",
              "title": "제목",
              "start": "시작 시각. 예: 2026-10-05T15:00:00+09:00 (모르면 null)",
              "location": "장소 (없으면 null)"
            }
          ]
        }

        규칙
        - 날짜와 시간이 함께 있는 약속은 event, 시간 없이 해야 할 일은 todo
        - 한 문장에 여러 개가 있으면 items에 모두 담아
        - todo는 날짜를 말했다면 start에 그 날짜의 09:00, 말하지 않았으면 null
        - 일정이나 할 일이 없는 대화라면 items는 빈 배열 []
        - 사용자의 요청을 이해하지 못했거나 일정/할 일을 판별할 수 없으면 reply를 정확히 "죄송합니다. 이해하지 못했습니다."로 하고 items는 빈 배열 []
        - '내일', '모레', '다음 주 화요일' 같은 말은 현재 시각을 기준으로 계산해
        - 사용자가 말하지 않은 정보를 지어내지 마
        """

        let text = try await send(system: system, user: userText, maxTokens: 2048, expectJSON: true)

        // AI 답변에서 맨 앞 { 부터 맨 뒤 } 까지만 잘라서 읽어요.
        guard let start = text.firstIndex(of: "{"),
              let end = text.lastIndex(of: "}"),
              let reply = try? JSONDecoder().decode(AIReply.self, from: Data(text[start...end].utf8))
        else { throw AIError.unreadable }

        return reply
    }

    // MARK: - 2) 오늘 하루 → 일기 초안

    func draftDiary(date: Date, weather: WeatherType,
                    doneTodos: [String], events: [String], memo: String) async throws -> String {
        let system = """
        너는 일기 쓰기를 돕는 비서야. 사용자가 준 재료로 그날을 돌아보는 일기 초안을 한국어로 써.
        - 1인칭, 따뜻하고 담백한 문체, 4~6문장
        - 재료에 없는 사실(사람 이름, 감정의 원인 등)을 지어내지 마
        - 재료가 적으면 짧게 써도 돼
        - 제목이나 목록 없이 본문만 출력해
        """

        func joined(_ list: [String]) -> String { list.isEmpty ? "없음" : list.joined(separator: ", ") }

        let user = """
        날짜: \(date.formatted(.dateTime.year().month().day().weekday(.wide)))
        날씨: \(weather.label)
        오늘 완료한 할 일: \(joined(doneTodos))
        오늘 일정: \(joined(events))
        내가 적어 둔 메모: \(memo.isEmpty ? "없음" : memo)
        """

        let text = try await send(system: system, user: user, maxTokens: 2048, expectJSON: false)
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw AIError.unreadable }
        return cleaned
    }

    // MARK: - 공통: Gemini에게 보내고 글자 받기

    private func send(system: String, user: String, maxTokens: Int, expectJSON: Bool) async throws -> String {
        // ① 동의 확인 — 동의 전에는 어떤 네트워크 호출도 하지 않아요.
        guard AIConsent.isGranted else { throw AIError.consentRequired }

        // ② 어디로 보낼지 정하기
        var request: URLRequest
        if let proxy = AppConfig.aiProxyURL {
            request = URLRequest(url: proxy)               // 우리 서버로 (권장)
        } else {
            #if DEBUG
            guard !APIKeyProvider.geminiAPIKey.isEmpty else { throw AIError.missingKey }
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(AppConfig.geminiModel):generateContent")
            else { throw AIError.notConfigured }
            request = URLRequest(url: url)                 // 연습용: 내가 직접 실행할 때만
            request.setValue(APIKeyProvider.geminiAPIKey, forHTTPHeaderField: "x-goog-api-key")
            #else
            throw AIError.notConfigured                    // 배포 빌드에는 키가 들어가지 않아요
            #endif
        }

        // ③ 보낼 내용 만들기 (Gemini 형식)
        request.httpMethod = "POST"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "content-type")

        var generationConfig: [String: Any] = ["maxOutputTokens": maxTokens]
        if expectJSON { generationConfig["responseMimeType"] = "application/json" }

        let body: [String: Any] = [
            "system_instruction": ["parts": [["text": system]]],
            "contents": [["role": "user", "parts": [["text": user]]]],
            "generationConfig": generationConfig
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        // ④ 보내기 — 서버가 잠깐 바쁘면(429·5xx) 기다렸다가 다시 시도해요 (2초, 4초 간격)
        var lastCode = 0
        var lastDetail: String?
        for attempt in 0..<maxAttempts {
            if attempt > 0 {
                try await Task.sleep(nanoseconds: UInt64(attempt) * 2_000_000_000)
            }

            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw AIError.unreadable }

            if http.statusCode == 200 {
                // ⑤ 답변에서 글자만 모으기
                let decoded = try JSONDecoder().decode(GeminiResponse.self, from: data)
                let text = decoded.candidates?.first?.content?.parts?
                    .compactMap(\.text).joined() ?? ""
                guard !text.isEmpty else { throw AIError.unreadable }
                return text
            }

            lastCode = http.statusCode
            lastDetail = (try? JSONDecoder().decode(GeminiErrorBody.self, from: data))?.error?.message
            if !retryableCodes.contains(http.statusCode) { break }   // 다시 해도 소용없는 오류
        }
        throw AIError.server(lastCode, lastDetail)
    }
}
