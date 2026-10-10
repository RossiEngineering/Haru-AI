// ============================================================
// 📄 AddEventView.swift  —  일정 추가 · 수정 화면
// ------------------------------------------------------------
// 입력 항목: 할 일(제목) · 시작/종료 시간 · 장소 · 알림 여부 · 메모
//  · 새 일정  : AddEventView(initialDate:)  → '저장'하면 새로 만들어요
//  · 수정     : AddEventView(editing:)      → 기존 일정의 값을 고쳐요
// 저장할 때 알림을 켰다면 알림도 (다시) 예약해요.
// ============================================================

import SwiftUI
import SwiftData

struct AddEventView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss   // 화면 닫기

    let editingEvent: CalendarEvent?   // nil = 새 일정

    @State private var title = ""
    @State private var startDate: Date
    @State private var endDate: Date
    @State private var location = ""
    @State private var memo = ""
    @State private var notifyEnabled = true

    /// 새 일정: 선택한 날짜의 오전 9시를 기본 시작 시간으로 잡아요.
    init(initialDate: Date) {
        editingEvent = nil
        let start = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: initialDate)
            ?? initialDate
        _startDate = State(initialValue: start)
        _endDate = State(initialValue: start.addingTimeInterval(3600))
    }

    /// 수정: 기존 일정의 값을 입력칸에 미리 채워요.
    init(editing event: CalendarEvent) {
        editingEvent = event
        _title = State(initialValue: event.title)
        _startDate = State(initialValue: event.startDate)
        _endDate = State(initialValue: event.endDate)
        _location = State(initialValue: event.location)
        _memo = State(initialValue: event.memo)
        _notifyEnabled = State(initialValue: event.notifyEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("할 일") {
                    TextField("무엇을 하나요?", text: $title)
                }
                Section("시간") {
                    DatePicker("시작", selection: $startDate)
                    DatePicker("종료", selection: $endDate, in: startDate...)
                }
                Section("장소") {
                    TextField("장소 (선택)", text: $location)
                }
                Section {
                    Toggle("알림 받기 (10분 전)", isOn: $notifyEnabled)
                }
                Section("메모") {
                    TextField("메모 (선택)", text: $memo, axis: .vertical)
                }
            }
            .scrollDismissesKeyboard(.interactively)   // 밀면 키보드가 내려가요
            .navigationTitle(editingEvent == nil ? "일정 추가" : "일정 수정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장", action: save)
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("키보드 내리기") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                        to: nil, from: nil, for: nil)
                    }
                }
            }
            // 시작 시간을 종료 시간보다 늦게 바꾸면 종료 시간도 같이 밀어줘요.
            .onChange(of: startDate) { _, newStart in
                if endDate < newStart { endDate = newStart.addingTimeInterval(3600) }
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespaces)

        if let event = editingEvent {
            // 수정: 기존 일정의 값을 바꾸고 알림을 다시 예약
            event.title = cleanTitle
            event.startDate = startDate
            event.endDate = endDate
            event.location = location
            event.memo = memo
            event.notifyEnabled = notifyEnabled
            NotificationService.schedule(for: event)
        } else {
            // 새로 만들기
            let event = CalendarEvent(title: cleanTitle, startDate: startDate, endDate: endDate,
                                      location: location, memo: memo, notifyEnabled: notifyEnabled)
            context.insert(event)
            NotificationService.schedule(for: event)
        }
        dismiss()
    }
}
