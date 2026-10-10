// ============================================================
// 📄 LoginView.swift  —  로그인 화면
// ------------------------------------------------------------
// 이메일과 비밀번호를 입력받아 로그인해요.
// 계정이 없으면 아래 '회원가입' 링크로 SignUpView 화면으로 넘어가요.
// 실제 로그인 확인은 AuthService가 하고, 이 파일은 화면 모양만 담당해요.
// ============================================================

import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var auth

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Spacer()

                Image(systemName: "sun.max.fill")
                    .font(.system(size: 64))
                Text("하루")
                    .font(.largeTitle.bold())
                Text("일정, 할 일, 일기를 한 곳에서")

                TextField("이메일", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)
                    .padding(.top, 24)

                SecureField("비밀번호", text: $password)
                    .textFieldStyle(.roundedBorder)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                }

                Button("로그인", action: logIn)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                NavigationLink("계정이 없나요? 회원가입") { SignUpView() }
                    .font(.footnote)

                Spacer()
            }
            .padding(24)
        }
    }

    private func logIn() {
        do {
            try auth.logIn(email: email, password: password)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
