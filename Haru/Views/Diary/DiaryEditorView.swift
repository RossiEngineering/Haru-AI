// ============================================================
// 📄 DiaryEditorView.swift  —  일기 쓰기/수정 화면
// ------------------------------------------------------------
// 입력 항목: 날짜 · 날씨 · 오늘 하루 글 · 사진(앨범에서 선택)
// entry 가 nil 이면 '새 일기', 값이 있으면 '기존 일기 수정'이에요.
//
// ✨ 저녁 회고: [일기 초안 만들기]를 누르면 그날 완료한 할 일·일정·날씨·메모로
//    AI가 초안을 써줘요. 마음에 들면 [적용하기]로 본문에 넣고 직접 고치면 돼요.
//    (처음 쓸 때는 AI 데이터 전송 동의 화면이 먼저 나와요)
// 키보드는 화면을 밀거나, 키보드 위 '키보드 내리기'로 내릴 수 있어요.
// ============================================================

import SwiftUI
import SwiftData
import PhotosUI

struct DiaryEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @Query private var allTodos: [TodoItem]
    @Query private var allEvents: [CalendarEvent]
    @AppStorage(AppSettings.aiConsentKey) private var aiConsent = false

    let entry: DiaryEntry?   // nil = 새 일기

    @State private var date: Date
    @State private var weather: WeatherType
    @State private var content: String
    @State private var photoData: Data?
    @State private var pickerItem: PhotosPickerItem?

    // AI 초안 상태
    @State private var draft: String?
    @State private var isDrafting = false
    @State private var draftError: String?
    @State private var showConsent = false

    init(entry: DiaryEntry?) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? .now)
        _weather = State(initialValue: entry?.weather ?? .sunny)
        _content = State(initialValue: entry?.content ?? "")
        _photoData = State(initialValue: entry?.photoData)
    }

    // 초안 재료: 선택한 날짜에 끝낸 할 일 / 있었던 일정
    private var doneTodoTitles: [String] {
        allTodos
            .filter { $0.isDone && Calendar.current.isDate($0.dueDate, inSameDayAs: date) }
            .map(\.title)
    }

    private var eventTitles: [String] {
        allEvents
            .filter { Calendar.current.isDate($0.startDate, inSameDayAs: date) }
            .sorted { $0.startDate < $1.startDate }
            .map { "\($0.startDate.formatted(.dateTime.hour().minute())) \($0.title)" }
    }

    var body: some View {
        Form {
            Section {
                DatePicker("날짜", selection: $date, displayedComponents: .date)
                Picker("날씨", selection: $weather) {
                    ForEach(WeatherType.allCases) { type in
                        Text("\(type.emoji) \(type.label)").tag(type)
                    }
                }
            }

            Section("오늘 하루") {
                TextEditor(text: $content)
                    .frame(minHeight: 180)
            }

            // ✨ 저녁 회고 → 일기 초안
            Section {
                Button(action: startDraft) {
                    Label(isDrafting ? "초안을 쓰는 중…" : "오늘 하루로 일기 초안 만들기",
                          systemImage: "sparkles")
                }
                .disabled(isDrafting)

                if let draft {
                    Text(draft)
                    HStack {
                        Button("적용하기") {
                            content = content.isEmpty ? draft : content + "\n\n" + draft
                            self.draft = nil
                        }
                        Button("다시 만들기", action: startDraft)
                        Button("닫기", role: .cancel) { self.draft = nil }
                    }
                    .buttonStyle(.borderless)
                }
                if let draftError {
                    Text(draftError).font(.footnote)
                }
            } header: {
                Text("저녁 회고")
            } footer: {
                Text("완료한 할 일 \(doneTodoTitles.count)개, 일정 \(eventTitles.count)개와 날씨, 위에 적은 글로 초안을 써요. 적용한 뒤에도 직접 고칠 수 있어요.")
            }

            Section("사진") {
                if let photoData, let image = UIImage(data: photoData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("사진 삭제", role: .destructive) { self.photoData = nil }
                }
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(photoData == nil ? "사진 추가" : "사진 바꾸기", systemImage: "photo")
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)   // 밀면 키보드가 내려가요
        .navigationTitle(entry == nil ? "일기 쓰기" : "일기 수정")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if entry == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("저장", action: save)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("키보드 내리기") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil, from: nil, for: nil)
                }
            }
        }
        .sheet(isPresented: $showConsent) {
            AIConsentView(
                onAgree: { aiConsent = true; showConsent = false; startDraft() },
                onCancel: { showConsent = false }
            )
        }
        // 사진을 고르면 불러와서 용량을 줄여 보관해요.
        .onChange(of: pickerItem) { _, item in
            Task { @MainActor in
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    photoData = image.jpegData(compressionQuality: 0.6)
                }
            }
        }
    }

    // MARK: - 동작들

    private func startDraft() {
        // 동의 전이면 동의 화면부터
        guard aiConsent else { showConsent = true; return }

        isDrafting = true
        draftError = nil

        Task { @MainActor in
            defer { isDrafting = false }
            do {
                draft = try await AIAssistantService().draftDiary(
                    date: date, weather: weather,
                    doneTodos: doneTodoTitles, events: eventTitles, memo: content)
            } catch AIAssistantService.AIError.consentRequired {
                aiConsent = false
                showConsent = true
            } catch {
                draftError = error.localizedDescription
            }
        }
    }

    private func save() {
        if let entry {
            // 기존 일기 → 값만 고쳐요
            entry.date = date
            entry.weather = weather
            entry.content = content
            entry.photoData = photoData
        } else {
            // 새 일기 → 저장소에 넣어요
            context.insert(DiaryEntry(date: date, weather: weather,
                                      content: content, photoData: photoData))
        }
        dismiss()
    }
}
