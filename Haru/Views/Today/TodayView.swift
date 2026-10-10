// ============================================================
// 📄 TodayView.swift  —  ⭐ 앱을 켜면 가장 먼저 보이는 '오늘' 화면
// ------------------------------------------------------------
// 보여주는 것
//   1) 오늘 남은 할 일이 몇 개인지
//   2) 오늘의 일정 목록
//   3) 오늘 할 일 목록 (체크 · 삭제 · 바로 추가 가능)
//        - 어제 못 끝낸 할 일도 오늘 목록에 같이 나와요.
// 오른쪽 위 톱니바퀴(⚙️)에서 설정 화면(알림·AI 동의·계정)을 열어요.
// (위젯 갱신은 이제 MainTabView가 맡아요)
// ============================================================

import SwiftUI
import SwiftData

struct TodayView: View {
    @Environment(\.modelContext) private var context   // 저장소 (넣기/지우기에 사용)

    // @Query = 저장소에서 자동으로 최신 목록을 가져와서 화면에 반영해 줘요.
    @Query(sort: \TodoItem.createdAt) private var allTodos: [TodoItem]
    @Query(sort: \CalendarEvent.startDate) private var allEvents: [CalendarEvent]

    @State private var newTodoTitle = ""
    @State private var showingSettings = false
    @FocusState private var isTodoFieldFocused: Bool
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""
    @AppStorage(AppSettings.cardColorKey) private var cardColor = AppSettings.defaultCardColor
    @AppStorage(AppSettings.cardOpacityKey) private var cardOpacity = AppSettings.defaultCardOpacity
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity
    private var theme: AppBackground { AppBackground(rawValue: background) ?? .system }
    private var cardFill: Color { (AppearanceColor(rawValue: cardColor) ?? .navy).color.opacity(cardOpacity) }
    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }

    // 오늘 할 일 = 오늘 날짜인 것 + 어제까지 못 끝낸 것
    private var todayTodos: [TodoItem] {
        let startOfToday = Calendar.current.startOfDay(for: .now)
        return allTodos.filter {
            Calendar.current.isDateInToday($0.dueDate) || (!$0.isDone && $0.dueDate < startOfToday)
        }
    }

    private var todayEvents: [CalendarEvent] {
        allEvents.filter { Calendar.current.isDateInToday($0.startDate) }
    }

    private var remainingCount: Int { todayTodos.filter { !$0.isDone }.count }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text(Date.now.formatted(.dateTime.month().day().weekday(.wide).locale(Locale(identifier: language))))
                        .font(.largeTitle.bold())
                        .foregroundStyle(Color.black)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .multilineTextAlignment(.center)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    Text(remainingCount == 0 ? "오늘 할 일을 모두 끝냈어요! 🎉"
                                             : "남은 할 일 \(remainingCount)개")
                        .font(.headline)
                        .listRowBackground(cardFill)
                }

                Section("오늘의 일정") {
                    if todayEvents.isEmpty {
                        Text("오늘은 일정이 없어요")
                            .foregroundStyle(ink.opacity(0.72))
                            .listRowBackground(cardFill)
                    }
                    ForEach(todayEvents) { event in
                        EventRow(event: event)
                            .listRowBackground(cardFill)
                    }
                }

                Section("오늘 할 일") {
                    ForEach(todayTodos) { todo in
                        TodoRow(todo: todo)
                            .listRowBackground(cardFill)
                    }
                        .onDelete(perform: deleteTodos)

                    HStack {
                        TextField("할 일을 입력하세요", text: $newTodoTitle)
                            .focused($isTodoFieldFocused)
                            .onSubmit(addTodo)
                        Button("추가", action: addTodo)
                            .disabled(newTodoTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .listRowBackground(cardFill)
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackgroundLayer(background: theme, imageData: Data(base64Encoded: backgroundImage)) }
            .foregroundStyle(ink)
            .tint(theme.accentColor)
            .scrollDismissesKeyboard(.interactively)   // 목록을 밀면 키보드가 내려가요
            .onTapGesture { isTodoFieldFocused = false }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                }
            }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }

    // MARK: - 동작들

    private func addTodo() {
        let title = newTodoTitle.trimmingCharacters(in: .whitespaces)
        guard !title.isEmpty else { return }
        context.insert(TodoItem(title: title))
        newTodoTitle = ""
    }

    private func deleteTodos(at offsets: IndexSet) {
        for index in offsets { context.delete(todayTodos[index]) }
    }
}
