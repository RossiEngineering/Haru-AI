// ============================================================
// 📄 SignUpView.swift  —  회원가입 화면
// ------------------------------------------------------------
// 이메일, 비밀번호, 비밀번호 확인을 입력받아 계정을 만들어요.
// 가입에 성공하면 자동으로 로그인되어 메인 화면으로 넘어가요.
// ============================================================

import SwiftUI

struct SignUpView: View {
    @Environment(AuthService.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var passwordCheck = ""
    @State private var errorMessage: String?

    var body: some View {
        Form {
            Section("계정 정보") {
                TextField("이메일", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                SecureField("비밀번호 (6자 이상)", text: $password)
                SecureField("비밀번호 확인", text: $passwordCheck)
            }

            if let errorMessage {
                Section { Text(errorMessage) }
            }

            Section {
                Button("가입하기", action: signUp)
            }
        }
        .navigationTitle("회원가입")
    }

    private func signUp() {
        guard password == passwordCheck else {
            errorMessage = "비밀번호가 서로 달라요."
            return
        }
        do {
            try auth.signUp(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
