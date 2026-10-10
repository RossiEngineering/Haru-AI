// ============================================================
// 📄 AIChatView.swift  —  AI 비서 채팅 화면 (글자 + 음성)
// ------------------------------------------------------------
// 사용 방법
//   · 글자로: "내일 3시에 치과, 금요일까지 보고서 제출" 입력 후 보내기
//   · 말로  : 🎤 버튼을 누르고 말하기 → 글자로 바뀌면 보내기
// 흐름
//   1) 내 말을 AI에게 보냄  →  2) AI가 일정/할 일 목록을 찾아냄
//   3) '확인 카드'로 먼저 보여줌  →  4) [저장]을 눌러야 실제로 저장
//
// 대화 바깥 여백을 누르면 키보드가 내려가고, 나가기 버튼으로 화면을 닫아요.
// ============================================================

import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var context
    @Binding var selectedTab: AppTab   // '나가기'로 다른 탭으로 이동할 때 사용

    @AppStorage(AppSettings.aiConsentKey) private var aiConsent = false
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity
    private var theme: AppBackground { AppBackground(rawValue: background) ?? .system }
    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }

    private static let welcome = "안녕하세요! 일정이나 할 일을 한 번에 말씀해 주세요.\n예: \"내일 3시에 치과, 금요일까지 보고서 제출, 우유 사기\""

    @State private var messages: [ChatMessage] = [ChatMessage(isUser: false, text: AIChatView.welcome)]
    @State private var input = ""
    @State private var isLoading = false
    @State private var showConsent = false
    @State private var speech = SpeechService()
    @FocusState private var inputFocused: Bool   // 키보드가 올라와 있는지

    var body: some View {
        NavigationStack {
            Group {
                if aiConsent { chatContent } else { consentGate }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("AI 비서").foregroundStyle(ink)
                }
                // ⑤ 나가기
                ToolbarItem(placement: .topBarLeading) {
                    Button("나가기", action: exitChat)
                }
            }
        }
        .sheet(isPresented: $showConsent) {
            AIConsentView(
                onAgree: { aiConsent = true; showConsent = false },
                onCancel: { showConsent = false; selectedTab = .today }
            )
        }
        // 처음 들어왔는데 동의 전이면 동의 화면부터 보여줘요.
        .onAppear { if !aiConsent { showConsent = true } }
        // 다른 탭으로 가면 키보드와 음성 인식을 정리해요.
        .onDisappear {
            inputFocused = false
            if speech.isRecording { speech.stop() }
        }
        // 말하는 동안 인식된 글자를 입력창에 실시간으로 채워줘요.
        .onChange(of: speech.transcript) { _, text in
            if speech.isRecording { input = text }
        }
    }

    // MARK: - 화면 조각들

    private var chatContent: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(messages) { row($0) }
                        if isLoading { ProgressView().padding() }
                    }
                    .padding()
                }
                .contentShape(Rectangle())
                .onTapGesture { inputFocused = false }
                .onChange(of: messages.count) { _, _ in
                    if let last = messages.last {
                        withAnimation { proxy.scrollTo(last.id, anchor: .bottom) }
                    }
                }
            }
            Divider()
            inputBar
        }
        .background { AppBackgroundLayer(background: theme, imageData: Data(base64Encoded: backgroundImage)) }
        .foregroundStyle(ink)
        .tint(theme.accentColor)
    }

    private var consentGate: some View {
        ContentUnavailableView {
            Label("AI 비서를 쓰려면 동의가 필요해요", systemImage: "lock.shield")
        } description: {
            Text("입력한 내용이 AI 제공업체(\(AppConfig.aiProviderName))로 전송돼요. 내용을 확인하고 동의해 주세요.")
        } actions: {
            Button("내용 확인하기") { showConsent = true }
                .buttonStyle(.borderedProminent)
        }
    }

    /// 말풍선 + (있으면) 확인 카드
    private func row(_ message: ChatMessage) -> some View {
        VStack(alignment: message.isUser ? .trailing : .leading, spacing: 8) {
            if !message.text.isEmpty { bubble(message) }
            if let proposal = message.proposal {
                ProposalCard(proposal: proposal,
                             onToggle: { toggle($0, in: message.id) },
                             onSave: { save(message.id) },
                             onCancel: { cancel(message.id) })
            }
        }
        .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
        .id(message.id)
    }

    private func bubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser { Spacer(minLength: 40) }
            Text(message.text)
                .padding(12)
                .background(message.isUser ? theme.accentColor : theme.rowColor,
                            in: RoundedRectangle(cornerRadius: 16))
                .foregroundStyle(message.isUser ? Color.white : ink)
            if !message.isUser { Spacer(minLength: 40) }
        }
    }

    private var inputBar: some View {
        HStack(spacing: 12) {
            Button(action: toggleMic) {
                Image(systemName: speech.isRecording ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title)
                    .foregroundStyle(speech.isRecording ? Color.red : theme.accentColor)
            }

            TextField("무엇을 도와드릴까요?", text: $input)
                .textFieldStyle(.roundedBorder)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit(send)

            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.title)
            }
            .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding()
    }

    // MARK: - 나가기 · 마이크 · 보내기

    /// 키보드·음성을 정리하고 '오늘' 탭으로 돌아가요.
    private func exitChat() {
        inputFocused = false
        if speech.isRecording { speech.stop() }
        selectedTab = .today
    }

    /// 마이크 버튼: 듣는 중이면 멈추고, 아니면 허락을 확인한 뒤 듣기 시작
    private func toggleMic() {
        if speech.isRecording {
            speech.stop()
            return
        }
        inputFocused = false   // ④ 말할 때는 키보드가 필요 없어요
        Task { @MainActor in
            guard await speech.requestPermission() else {
                messages.append(ChatMessage(isUser: false,
                    text: "마이크 또는 음성 인식 권한이 필요해요. 설정 앱에서 허용해 주세요."))
                return
            }
            do { try speech.start() }
            catch {
                messages.append(ChatMessage(isUser: false,
                    text: "음성 인식을 시작하지 못했어요: \(error.localizedDescription)"))
            }
        }
    }

    /// 보내기: AI에게 묻고 → 결과를 확인 카드로 보여줘요. (저장은 카드에서 따로 눌러야 해요)
    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isLoading else { return }
        if speech.isRecording { speech.stop() }

        messages.append(ChatMessage(isUser: true, text: text))
        input = ""
        isLoading = true

        Task { @MainActor in
            defer { isLoading = false }
            do {
                let result = try await AIAssistantService().parseCommand(text)
                messages.append(makeReply(from: result))
            } catch AIAssistantService.AIError.consentRequired {
                aiConsent = false
                showConsent = true
            } catch AIAssistantService.AIError.unreadable {
                messages.append(ChatMessage(isUser: false, text: "죄송합니다. 이해하지 못했습니다."))
            } catch {
                messages.append(ChatMessage(isUser: false,
                    text: "앗, 문제가 생겼어요.\n\(error.localizedDescription)"))
            }
        }
    }

    // MARK: - 확인 카드 처리

    /// AI 답변을 말풍선 + 확인 카드로 바꿔요. 시간이 없는 '일정'은 카드에서 빼고 알려줘요.
    private func makeReply(from result: AIReply) -> ChatMessage {
        let misunderstood = "죄송합니다. 이해하지 못했습니다."
        if result.reply.trimmingCharacters(in: .whitespacesAndNewlines) == misunderstood {
            return ChatMessage(isUser: false, text: misunderstood)
        }

        var valid: [ProposalItem] = []
        var skipped: [String] = []

        for item in result.items {
            let title = (item.title ?? "").trimmingCharacters(in: .whitespaces)
            guard !title.isEmpty else { continue }
            if item.isEvent && item.startDate == nil { skipped.append(title); continue }
            if item.isEvent || item.isTodo { valid.append(ProposalItem(item: item)) }
        }

        var text = result.reply
        if !skipped.isEmpty {
            text += "\n(시간을 알아듣지 못한 일정: \(skipped.joined(separator: ", ")) — 날짜와 시간을 같이 말씀해 주세요)"
        }
        return ChatMessage(isUser: false, text: text,
                           proposal: valid.isEmpty ? nil : Proposal(items: valid))
    }

    private func toggle(_ itemID: UUID, in messageID: UUID) {
        guard let m = messages.firstIndex(where: { $0.id == messageID }),
              var proposal = messages[m].proposal,
              let i = proposal.items.firstIndex(where: { $0.id == itemID }) else { return }
        proposal.items[i].isSelected.toggle()
        messages[m].proposal = proposal
    }

    private func save(_ messageID: UUID) {
        guard let m = messages.firstIndex(where: { $0.id == messageID }),
              var proposal = messages[m].proposal,
              proposal.status == .waiting else { return }

        let selected = proposal.items.filter(\.isSelected)
        for entry in selected { insert(entry.item) }
        proposal.status = selected.isEmpty ? .cancelled : .saved
        messages[m].proposal = proposal
    }

    private func cancel(_ messageID: UUID) {
        guard let m = messages.firstIndex(where: { $0.id == messageID }),
              var proposal = messages[m].proposal else { return }
        proposal.status = .cancelled
        messages[m].proposal = proposal
    }

    /// 항목 하나를 실제로 저장해요.
    private func insert(_ item: AIItem) {
        let title = (item.title ?? "").trimmingCharacters(in: .whitespaces)
        if item.isEvent, let start = item.startDate {
            let event = CalendarEvent(title: title, startDate: start, location: item.location ?? "")
            context.insert(event)
            NotificationService.schedule(for: event)
        } else {
            context.insert(TodoItem(title: title, dueDate: item.startDate ?? .now))
        }
    }
}
