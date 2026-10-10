// ============================================================
// 📄 KeychainHelper.swift  —  비밀번호 보관 금고
// ------------------------------------------------------------
// 아이폰에는 '키체인'이라는 암호 전용 금고가 있어요.
// 비밀번호처럼 민감한 정보는 일반 저장소 대신 이 금고에 넣는 게 안전해요.
// 이 파일은 금고에 "넣기(save)", "꺼내기(read)", "지우기(delete)"를 담당해요.
// ============================================================

import Foundation
import Security

enum KeychainHelper {
    private static let service = "com.haru.auth"

    private static func baseQuery(account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }

    static func save(account: String, value: String) {
        let base = baseQuery(account: account)
        SecItemDelete(base as CFDictionary)           // 같은 이름이 있으면 먼저 지우고
        var item = base
        item[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(item as CFDictionary, nil)          // 새로 넣어요
    }

    static func read(account: String) -> String? {
        var query = baseQuery(account: account)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// 금고에서 지우기 (계정 삭제에 사용)
    static func delete(account: String) {
        SecItemDelete(baseQuery(account: account) as CFDictionary)
    }
}
