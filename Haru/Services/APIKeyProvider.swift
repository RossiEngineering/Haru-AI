// ============================================================
// 📄 APIKeyProvider.swift — Xcode 실행 환경에서 Gemini 키 읽기
// ------------------------------------------------------------
// API 키를 소스 코드나 GitHub에 적지 않아요.
// Xcode Scheme의 Run 환경 변수 GEMINI_API_KEY에서 읽고,
// 값이 없으면 AI 요청을 보내지 않아요.
// 자세한 설정은 docs/SETUP_GUIDE.md를 참고하세요.
// ============================================================

import Foundation

enum APIKeyProvider {
    static var geminiAPIKey: String {
        ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? ""
    }
}
