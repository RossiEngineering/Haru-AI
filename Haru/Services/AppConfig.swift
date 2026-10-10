// ============================================================
// 📄 AppConfig.swift  —  앱의 "연결 설정" 모음
// ------------------------------------------------------------
// aiProviderName : 동의 화면·설정 화면에 보여줄 AI 회사 이름
//                  (AI 회사를 바꾸면 여기 한 줄만 고치면 돼요)
// geminiModel    : 사용할 Gemini 모델 이름
//                  ⚠️ 예전부터 쓰던 모델 이름이 있다면 그 이름으로 바꾸세요.
// aiProxyURL     : AI를 대신 호출해 주는 '우리 서버'의 주소 (아직 비어 있어요)
//   · 서버를 만들면 여기에 주소를 넣어요.
//   · 비어 있으면(nil) 연습용 모드로 동작해요:
//       - Xcode로 직접 실행(Debug)할 때만 GEMINI_API_KEY 환경 변수로 AI를 호출
//       - 앱스토어/TestFlight용(Release) 빌드에서는 AI가 꺼져요 → 키가 앱에 들어가지 않게 막는 안전장치
// ============================================================

import Foundation

enum AppConfig {
    static let aiProviderName = "Google Gemini"
    static let geminiModel = "gemini-2.5-flash"

    /// 예: URL(string: "https://내서버주소/haru-ai")
    static let aiProxyURL: URL? = nil
}
