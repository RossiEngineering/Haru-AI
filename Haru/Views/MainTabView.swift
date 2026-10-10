// ============================================================
// 📄 MainTabView.swift  —  좌우 스와이프 화면 + 위젯·알림 관리 본부
// ------------------------------------------------------------
// 1) 화면 4개를 좌우로 넘겨요: 오늘 · 캘린더 · AI 비서 · 일기장
//    현재 페이지(selection)를 들고 있어서, AI 화면의 '나가기' 버튼이
//    오늘 화면으로 돌아갈 수 있어요.
//
// 2) 위젯과 알림을 최신으로 유지하는 '본부' 역할도 해요.   ← 고객 리뷰 "위젯이 안 떠요" 수정
//    예전에는 '오늘' 화면이 켜져 있을 때만 위젯을 갱신해서, AI 채팅이나 캘린더에서
//    추가한 할 일이 위젯에 안 나올 수 있었어요.
//    이제는 어느 화면에서 바꾸든, 앱이 켜지거나 꺼질 때든 여기서 한 번에 갱신해요.
// ============================================================

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case today, calendar, ai, diary

    var title: String {
        switch self {
        case .today: "오늘"
        case .calendar: "캘린더"
        case .ai: "AI 비서"
        case .diary: "일기장"
        }
    }

    var symbol: String {
        switch self {
        case .today: "checklist"
        case .calendar: "calendar"
        case .ai: "sparkles"
        case .diary: "book.closed"
        }
    }
}

struct MainTabView: View {
    @Environment(\.scenePhase) private var scenePhase

    // 전체 할 일·일정을 지켜보다가 바뀌면 syncKey가 달라져요.
    @Query private var todos: [TodoItem]
    @Query private var events: [CalendarEvent]

    @AppStorage(AppSettings.morningEnabledKey) private var morningEnabled = true
    @AppStorage(AppSettings.morningHourKey)    private var morningHour = 8
    @AppStorage(AppSettings.eveningEnabledKey) private var eveningEnabled = false
    @AppStorage(AppSettings.eveningHourKey)    private var eveningHour = 21
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""

    @State private var selection: AppTab = .today
    private var theme: AppBackground { AppBackground(rawValue: background) ?? .cream }

    /// 이 글자가 바뀌면 "위젯과 브리핑 알림을 다시 만들어야 한다"는 신호예요.
    private var syncKey: String {
        let todoPart = todos
            .map { "\($0.title)|\($0.dueDate.timeIntervalSince1970)|\($0.isDone)" }
            .joined(separator: ";")
        let eventPart = events
            .map { "\($0.title)|\($0.startDate.timeIntervalSince1970)|\($0.endDate.timeIntervalSince1970)|\($0.location)" }
            .joined(separator: ";")
        return "\(todoPart)#\(eventPart)#\(morningEnabled)\(morningHour)\(eveningEnabled)\(eveningHour)"
    }

    var body: some View {
        TabView(selection: $selection) {
            TodayView()
                .tag(AppTab.today)

            CalendarView()
                .tag(AppTab.calendar)

            AIChatView(selectedTab: $selection)
                .tag(AppTab.ai)

            DiaryListView()
                .tag(AppTab.diary)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .safeAreaInset(edge: .bottom, spacing: 0) {
            bottomNavigation
        }
        .background {
            AppBackgroundLayer(background: theme, imageData: Data(base64Encoded: backgroundImage))
        }
        .environment(\.locale, Locale(identifier: language))
        .tint(theme.accentColor)
        // 앱이 처음 나타날 때: 알림 허락을 묻고 위젯·알림을 맞춰 둬요.
        .task {
            await NotificationService.requestPermission()
            syncAll()
        }
        // 할 일·일정·알림 설정이 바뀔 때마다
        .onChange(of: syncKey) { _, _ in syncAll() }
        // 앱이 켜지거나 백그라운드로 갈 때도 한 번 더 (안전장치)
        .onChange(of: scenePhase) { _, phase in
            if phase != .inactive { syncAll() }
        }
    }

    private func syncAll() {
        WidgetSyncService.update(todos: todos, events: events)
        BriefingService.reschedule(todos: todos, events: events,
                                   morningEnabled: morningEnabled, morningHour: morningHour,
                                   eveningEnabled: eveningEnabled, eveningHour: eveningHour)
    }

    private var bottomNavigation: some View {
        HStack(spacing: 6) {
            ForEach([AppTab.today, .calendar, .ai, .diary], id: \.self) { tab in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: tab.symbol)
                            .font(.system(size: 21, weight: .semibold))
                        Text(tab.title)
                            .font(.caption2.weight(.medium))
                    }
                    .foregroundStyle(selection == tab ? theme.accentColor : Color.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background {
                        if selection == tab {
                            Capsule().fill(Color.primary.opacity(0.08))
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.title)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(7)
        .background(.regularMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .padding(.bottom, 6)
    }
}
