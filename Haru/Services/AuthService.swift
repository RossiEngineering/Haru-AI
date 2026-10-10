// ============================================================
// 📄 AuthService.swift  —  회원가입 · 로그인 · 로그아웃 · 계정 삭제
// ------------------------------------------------------------
// 지금 버전은 '이 폰 안에서만' 동작하는 계정이에요. (서버가 없어요)
//  - 회원가입: 이메일 + 비밀번호를 검사하고, 비밀번호는 암호처럼 변환(해시)해서
//              키체인 금고에 저장해요. 원래 비밀번호는 어디에도 저장하지 않아요.
//  - 로그인  : 입력한 비밀번호를 같은 방식으로 변환해서 금고 속 값과 비교해요.
//  - 계정 삭제: 금고의 계정, 일정·할 일·일기, 예약된 알림, 위젯 내용을 모두 지워요.
//              (Apple 심사 규칙: 가입이 있는 앱은 앱 안에서 계정 삭제가 가능해야 해요)
// 나중에 진짜 서비스로 키우면 이 파일 하나만 Firebase 같은 서버 로그인으로
// 바꾸면 돼요.
// ============================================================

import Foundation
import CryptoKit
import SwiftData

@Observable
final class AuthService {
    /// 지금 로그인한 사람의 이메일 (nil이면 로그아웃 상태)
    private(set) var currentEmail: String?
    var isLoggedIn: Bool { currentEmail != nil }

    private let sessionKey = "haru.currentEmail"

    init() {
        // 앱을 껐다 켜도 로그인이 유지되도록 마지막 로그인 정보를 불러와요.
        currentEmail = UserDefaults.standard.string(forKey: sessionKey)
    }

    // 사용자에게 보여줄 오류 문구들
    enum AuthError: LocalizedError {
        case invalidEmail, weakPassword, emailTaken, wrongCredentials

        var errorDescription: String? {
            switch self {
            case .invalidEmail:      return "이메일 형식이 올바르지 않아요."
            case .weakPassword:      return "비밀번호는 6자 이상으로 만들어 주세요."
            case .emailTaken:        return "이미 가입된 이메일이에요."
            case .wrongCredentials:  return "이메일 또는 비밀번호가 맞지 않아요."
            }
        }
    }

    func signUp(email: String, password: String) throws {
        let email = normalize(email)
        guard email.contains("@"), email.contains(".") else { throw AuthError.invalidEmail }
        guard password.count >= 6 else { throw AuthError.weakPassword }
        guard KeychainHelper.read(account: email) == nil else { throw AuthError.emailTaken }

        KeychainHelper.save(account: email, value: hash(password))
        startSession(email)
    }

    func logIn(email: String, password: String) throws {
        let email = normalize(email)
        guard let saved = KeychainHelper.read(account: email), saved == hash(password) else {
            throw AuthError.wrongCredentials
        }
        startSession(email)
    }

    func logOut() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
        currentEmail = nil
    }

    /// 계정과 이 폰 안의 모든 데이터를 지워요. 되돌릴 수 없어요.
    func deleteAccount(context: ModelContext) throws {
        guard let email = currentEmail else { return }

        // 1) 저장된 일정·할 일·일기 삭제
        try context.delete(model: CalendarEvent.self)
        try context.delete(model: TodoItem.self)
        try context.delete(model: DiaryEntry.self)
        try context.save()

        // 2) 비밀번호 금고, AI 동의, 알림, 위젯 정리
        KeychainHelper.delete(account: email)
        AIConsent.revoke()
        NotificationService.cancelAll()
        WidgetSyncService.clear()

        // 3) 로그아웃
        logOut()
    }

    // MARK: - 내부 도우미

    private func startSession(_ email: String) {
        UserDefaults.standard.set(email, forKey: sessionKey)
        currentEmail = email
    }

    private func normalize(_ email: String) -> String {
        email.trimmingCharacters(in: .whitespaces).lowercased()
    }

    /// 비밀번호를 되돌릴 수 없는 긴 글자로 바꿔요. (SHA-256)
    private func hash(_ password: String) -> String {
        SHA256.hash(data: Data(password.utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }
}
