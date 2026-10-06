// ============================================================
// 📄 AIAssistantService.swift — Gemini AI 비서
// ------------------------------------------------------------
// 사용자가 입력한(또는 음성으로 입력한) 문장을 Gemini API에 보내고,
// Haru가 이해할 수 있는 AIAction(JSON 지시서)으로 받아오는 담당이에요.
//
// 현재 흐름
//   1) 사용자 문장 준비
//   2) Gemini 3.8 Flash에 요청
//   3) JSON 형식의 add_event / add_todo / chat 응답 받기
//   4) AIAction으로 변환해서 화면이 실제 동작을 수행
//
// ⚠️ 보안 주의
// 개발/학습 단계에서는 Secrets.swift에 API 키를 넣지만,
// 실제 배포 앱에서는 키가 노출되지 않도록 서버를 거쳐 API를 호출해야 해요.
// ============================================================

import Foundation

struct AIAssistantService {

    enum AIError: LocalizedError {
        case missingKey
        case invalidURL
        case server(Int, String)
        case emptyResponse
        case unreadable

        var errorDescription: String? {
            switch self {
            case .missingKey:
                return "Gemini API 키가 비어 있어요. Secrets.swift에 키를 넣어 주세요."
            case .invalidURL:
                return "Gemini API 주소를 만들지 못했어요."
            case .server(let code, let message):
                let detail = message.trimmingCharacters(in: .whitespacesAndNewlines)
                return detail.isEmpty
                    ? "Gemini 서버에서 오류가 났어요 (코드 \(code))."
                    : "Gemini 서버 오류 (\(code))\n\(detail)"
            case .emptyResponse:
                return "Gemini가 답을 보내지 않았어요. 다시 말씀해 주세요."
            case .unreadable:
                return "Gemini의 답을 이해하지 못했어요. 한 번만 더 말씀해 주세요."
            }
        }
    }

    private let model = "gemini-3.8-flash"

    private var endpoint: URL? {
        URL(
            string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
        )
    }

    private var apiKey: String {
        Secrets.geminiAPIKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
    }

    private struct APIResponse: Decodable {
        let candidates: [Candidate]?
        struct Candidate: Decodable { let content: Content? }
        struct Content: Decodable { let parts: [Part]? }
        struct Part: Decodable { let text: String? }
    }

    private struct APIErrorResponse: Decodable {
        let error: APIError?
        struct APIError: Decodable {
            let message: String?
            let status: String?
            let code: Int?
        }
    }

    func ask(_ userText: String) async throws -> AIAction {
        guard !apiKey.isEmpty else { throw AIError.missingKey }
        guard let endpoint else { throw AIError.invalidURL }

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = .current
        let now = formatter.string(from: .now)

        let systemPrompt = """
        너는 '하루(Haru)' 일정 관리 앱의 AI 비서야.

        현재 날짜와 시간:
        \(now)

        현재 시간대:
        \(TimeZone.current.identifier)

        사용자의 말을 읽고 반드시 JSON 객체 하나만 반환해.
        JSON 밖의 설명, 문장, 마크다운, 코드블록은 출력하지 마.

        반환 형식:
        {
          "type": "add_event" 또는 "add_todo" 또는 "chat",
          "title": "일정 또는 할 일 제목",
          "start": "ISO 8601 시작 시각 또는 null",
          "location": "장소 또는 null",
          "reply": "사용자에게 보여줄 친절한 한국어 한 문장"
        }

        규칙:
        - 날짜와 시간이 포함된 약속/일정은 type = add_event
        - 해야 할 일은 type = add_todo
        - 단순 질문/대화는 type = chat
        - '내일', '모레', '다음 주 화요일' 등은 현재 시각을 기준으로 계산
        - add_event의 start는 예: 2026-10-06T15:00:00+09:00
        - 시간대까지 알 수 없으면 현재 기기 시간대를 사용
        - add_todo에 날짜만 있다면 그 날짜 09:00을 start로 사용
        - 날짜 정보가 전혀 없는 add_todo는 start = null
        - chat은 title/start/location을 null로 사용
        - reply는 자연스러운 한국어 한 문장
        - 결과는 반드시 유효한 JSON 하나만 반환
        """

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

        let body: [String: Any] = [
            "systemInstruction": ["parts": [["text": systemPrompt]]],
            "contents": [["role": "user", "parts": [["text": userText]]]],
            "generationConfig": [
                "responseMimeType": "application/json",
                "temperature": 0.2,
                "maxOutputTokens": 500
            ]
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let delays: [UInt64] = [0, 2, 4]

        for (attempt, delay) in delays.enumerated() {
            if delay > 0 {
                try await Task.sleep(for: .seconds(delay))
            }

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse else {
                throw AIError.server(0, "HTTP 응답을 확인할 수 없어요.")
            }

            if (200...299).contains(http.statusCode) {
                return try decodeAction(from: data)
            }

            let (message, status) = decodeAPIError(from: data)
            let retryable = [429, 500, 502, 503, 504].contains(http.statusCode)

            if retryable && attempt < delays.count - 1 {
                continue
            }

            let detail = status.map { "\($0): \(message)" } ?? message
            throw AIError.server(http.statusCode, detail)
        }

        throw AIError.server(0, "Gemini 요청을 완료하지 못했어요.")
    }

    private func decodeAction(from data: Data) throws -> AIAction {
        let decoded: APIResponse

        do {
            decoded = try JSONDecoder().decode(APIResponse.self, from: data)
        } catch {
            throw AIError.unreadable
        }

        guard
            let candidates = decoded.candidates,
            let first = candidates.first,
            let parts = first.content?.parts
        else {
            throw AIError.emptyResponse
        }

        let text = parts
            .compactMap(\.text)
            .joined()
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !text.isEmpty else { throw AIError.emptyResponse }

        guard
            let start = text.firstIndex(of: "{"),
            let end = text.lastIndex(of: "}")
        else {
            throw AIError.unreadable
        }

        let jsonText = String(text[start...end])

        do {
            return try JSONDecoder().decode(
                AIAction.self,
                from: Data(jsonText.utf8)
            )
        } catch {
            throw AIError.unreadable
        }
    }

    private func decodeAPIError(from data: Data) -> (message: String, status: String?) {
        if let decoded = try? JSONDecoder().decode(APIErrorResponse.self, from: data),
           let error = decoded.error {
            return (error.message ?? "", error.status)
        }

        return (String(data: data, encoding: .utf8) ?? "", nil)
    }
}
