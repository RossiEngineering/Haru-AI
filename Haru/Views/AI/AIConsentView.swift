// ============================================================
// 📄 AIConsentView.swift  —  "AI에게 내 글을 보내도 될까요?" 동의 화면
// ------------------------------------------------------------
// AI 기능은 입력한 글을 외부 AI 회사(AppConfig.aiProviderName)로 보내서 처리해요.
// Apple 심사 규칙상 '누구에게, 무엇을 보내는지' 밝히고 동의를 받아야 해서,
// AI 비서와 일기 초안을 처음 쓸 때 이 화면을 보여줘요.
// (설정 화면에서 언제든 동의를 끌 수 있어요)
// ============================================================

import SwiftUI

struct AIConsentView: View {
    let onAgree: () -> Void
    let onCancel: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                    Text("AI 기능을 쓰기 전에\n확인해 주세요")
                        .font(.title2.bold())

                    block("누구에게 보내나요?",
                          "AI 제공업체: \(AppConfig.aiProviderName)\n입력한 내용이 이곳으로 전송돼 처리돼요. (우리 서버를 거칠 수 있어요)")
                    block("무엇을 보내나요?",
                          "• AI 비서: 내가 입력하거나 말한 문장 (음성은 글자로 바뀐 뒤 전송), 현재 시각\n• 일기 초안: 그날의 날씨, 완료한 할 일과 일정의 제목, 내가 적어 둔 메모")
                    block("보내지 않는 것",
                          "계정 이메일, 비밀번호, 일기에 붙인 사진은 보내지 않아요.")
                    block("언제든 바꿀 수 있어요",
                          "설정 ⚙️ → 'AI에 데이터 전송 동의'에서 끄면 AI 기능이 멈춰요.")
                }
                .padding()
            }
            // 버튼을 화면 아래에 고정
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    Button(action: onAgree) {
                        Text("동의하고 시작").frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    Button("나중에", action: onCancel)
                }
                .padding()
                .background(.bar)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func block(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text)
        }
    }
}
