// ============================================================
// 📄 SettingsView.swift  —  설정 화면
// ------------------------------------------------------------
//  · 계정    : 이메일 확인, 로그아웃, 계정 삭제(모든 데이터 삭제)
//  · 알림    : 아침 브리핑 / 저녁 일기 알림 켜기·끄기와 시간 선택
//  · AI      : 데이터 전송 동의 켜기·끄기 (끄면 AI 기능이 멈춰요)
//  · 위젯    : 위젯 연결 상태 점검 + 지금 새로고침
// 오늘 화면의 톱니바퀴(⚙️)로 열려요.
// ============================================================

import SwiftUI
import SwiftData
import PhotosUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AuthService.self) private var auth

    @Query private var todos: [TodoItem]
    @Query private var events: [CalendarEvent]

    @AppStorage(AppSettings.morningEnabledKey) private var morningEnabled = true
    @AppStorage(AppSettings.morningHourKey)    private var morningHour = 8
    @AppStorage(AppSettings.eveningEnabledKey) private var eveningEnabled = false
    @AppStorage(AppSettings.eveningHourKey)    private var eveningHour = 21
    @AppStorage(AppSettings.aiConsentKey)      private var aiConsent = false
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""
    @State private var showDeleteConfirm = false
    @State private var errorMessage: String?
    @State private var widgetRefreshed = false
    @State private var selectedPhoto: PhotosPickerItem?
    @Environment(\.colorScheme) private var colorScheme

    private var systemTextColor: Color { colorScheme == .dark ? .white : .black }

    var body: some View {
        NavigationStack {
            Form {
                Section("배경") {
                    PhotosPicker(selection: $selectedPhoto, matching: .images, photoLibrary: .shared()) {
                        Label(backgroundImage.isEmpty ? "사진 선택" : "사진 바꾸기", systemImage: "photo")
                    }
                    if !backgroundImage.isEmpty {
                        Label("선택한 사진을 배경으로 사용 중", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Button("사진 배경 제거", systemImage: "trash", role: .destructive) {
                            backgroundImage = ""
                            background = AppSettings.defaultBackground
                            selectedPhoto = nil
                        }
                    }
                }

                Section {
                    Picker("언어", selection: $language) {
                        ForEach(AppLanguage.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                } header: {
                    Text("언어")
                } footer: {
                    Text("날짜와 시스템 형식에 적용돼요. 화면 문구의 다국어 번역은 아직 제공되지 않아요.")
                }

                Section("계정") {
                    LabeledContent("이메일", value: auth.currentEmail ?? "-")
                    Button("로그아웃") { auth.logOut() }
                    Button("계정 삭제", role: .destructive) { showDeleteConfirm = true }
                    if let errorMessage {
                        Text(errorMessage).font(.footnote)
                    }
                }

                Section {
                    Toggle("☀️ 아침 브리핑", isOn: $morningEnabled)
                    if morningEnabled {
                        Picker("시간", selection: $morningHour) {
                            ForEach(5..<12, id: \.self) { hour in Text("\(hour)시").tag(hour) }
                        }
                    }
                    Toggle("🌙 저녁 일기 알림", isOn: $eveningEnabled)
                    if eveningEnabled {
                        Picker("시간", selection: $eveningHour) {
                            ForEach(18..<24, id: \.self) { hour in Text("\(hour)시").tag(hour) }
                        }
                    }
                } header: {
                    Text("알림")
                } footer: {
                    Text("아침 브리핑은 앞으로 7일치를 미리 예약해요. 앱을 일주일 넘게 열지 않으면 멈출 수 있어요.")
                }

                Section {
                    Toggle("AI에 데이터 전송 동의", isOn: $aiConsent)
                } header: {
                    Text("AI")
                } footer: {
                    Text("AI 비서와 일기 초안을 쓸 때 입력한 문장·일정/할 일 제목·메모가 AI 제공업체(\(AppConfig.aiProviderName))로 전송돼요. 끄면 AI 기능이 멈춰요.")
                }

                Section {
                    LabeledContent("위젯 연결", value: WidgetSnapshot.isAppGroupAvailable ? "정상 ✅" : "설정 필요 ⚠️")
                    Button(widgetRefreshed ? "새로고침했어요 ✓" : "위젯 지금 새로고침") {
                        WidgetSyncService.update(todos: todos, events: events)
                        widgetRefreshed = true
                    }
                } header: {
                    Text("위젯")
                } footer: {
                    if !WidgetSnapshot.isAppGroupAvailable {
                        Text("위젯과 데이터를 주고받으려면 Xcode의 App Groups 설정이 필요해요. 앱과 위젯 두 곳 모두에 같은 이름을 추가하고, SharedConfig.swift의 이름과 똑같이 맞춰 주세요.")
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(uiColor: .systemBackground))
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: selectedPhoto) { _, item in
                guard let item else { return }
                Task {
                    guard let data = try? await item.loadTransferable(type: Data.self),
                          let image = UIImage(data: data),
                          let optimizedData = optimizedJPEG(from: image) else { return }
                    backgroundImage = optimizedData.base64EncodedString()
                    background = AppBackground.photo.rawValue
                }
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("완료") { dismiss() } }
            }
            .confirmationDialog("계정을 삭제할까요?", isPresented: $showDeleteConfirm,
                                titleVisibility: .visible) {
                Button("계정과 모든 데이터 삭제", role: .destructive, action: deleteAccount)
                Button("취소", role: .cancel) {}
            } message: {
                Text("일정·할 일·일기가 모두 지워지고 되돌릴 수 없어요.")
            }
        }
        .foregroundStyle(systemTextColor)
        .tint(Color.accentColor)
    }

    private func deleteAccount() {
        do {
            try auth.deleteAccount(context: context)
        } catch {
            errorMessage = "삭제하지 못했어요: \(error.localizedDescription)"
        }
    }

    private func optimizedJPEG(from image: UIImage) -> Data? {
        let sourceSize = image.size
        let scale = min(1, 1400 / max(sourceSize.width, sourceSize.height))
        let targetSize = CGSize(width: sourceSize.width * scale, height: sourceSize.height * scale)
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        let resized = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
        return resized.jpegData(compressionQuality: 0.76)
    }

}
