// ============================================================
// 📄 CalendarView.swift  —  월간 캘린더 화면
// ------------------------------------------------------------
//  - 위쪽: 달력 (일정이 있는 날에는 작은 점이 찍혀요)
//  - 날짜를 누르면 아래에 그날의 일정 목록이 나와요
//  - 일정을 누르면 수정 화면, 왼쪽으로 밀면 삭제 (예약된 알림도 같이 취소)
//  - 오른쪽 위 + 버튼 → 일정 추가 화면(AddEventView)
// ============================================================

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \CalendarEvent.startDate) private var events: [CalendarEvent]
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""
    @AppStorage(AppSettings.cardColorKey) private var cardColor = AppSettings.defaultCardColor
    @AppStorage(AppSettings.cardOpacityKey) private var cardOpacity = AppSettings.defaultCardOpacity
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue

    @State private var selectedDate = Date()   // 내가 누른 날짜
    @State private var monthAnchor = Date()    // 지금 보고 있는 달
    @State private var showingAdd = false
    @State private var editingEvent: CalendarEvent?   // 수정할 일정

    private let calendar = Calendar.current
    private let weekdayNames = ["일", "월", "화", "수", "목", "금", "토"]
    private var theme: AppBackground { AppBackground(rawValue: background) ?? .system }
    private var cardFill: Color { (AppearanceColor(rawValue: cardColor) ?? .navy).color.opacity(cardOpacity) }
    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }

    // 이번 달 칸 만들기: 1일이 시작되는 요일만큼 빈칸(nil)을 먼저 채우고, 그다음 날짜들
    private var dayCells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: monthAnchor),
              let dayCount = calendar.range(of: .day, in: .month, for: monthAnchor)?.count
        else { return [] }

        let blanks = calendar.component(.weekday, from: interval.start) - 1  // 일요일=1
        var cells: [Date?] = Array(repeating: nil, count: blanks)
        for offset in 0..<dayCount {
            cells.append(calendar.date(byAdding: .day, value: offset, to: interval.start))
        }
        return cells
    }

    private var eventsOnSelectedDay: [CalendarEvent] {
        events.filter { calendar.isDate($0.startDate, inSameDayAs: selectedDate) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 8) {
                monthHeader
                weekGrid
                Divider()
                List {
                    if eventsOnSelectedDay.isEmpty {
                        Text("이 날은 일정이 없어요")
                            .foregroundStyle(ink.opacity(0.72))
                            .listRowBackground(cardFill)
                    }
                    ForEach(eventsOnSelectedDay) { event in
                        Button { editingEvent = event } label: {
                            EventRow(event: event)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(cardFill)
                    }
                    .onDelete(perform: deleteEvents)
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
            .background { AppBackgroundLayer(background: theme, imageData: Data(base64Encoded: backgroundImage)) }
            .foregroundStyle(ink)
            .tint(theme.accentColor)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("캘린더").foregroundStyle(Color.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingAdd = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddEventView(initialDate: selectedDate)
            }
            .sheet(item: $editingEvent) { event in
                AddEventView(editing: event)
            }
        }
    }

    // MARK: - 화면 조각들

    private var monthHeader: some View {
        HStack {
            Button { moveMonth(-1) } label: { Image(systemName: "chevron.left") }
            Spacer()
            Text(monthAnchor.formatted(.dateTime.year().month().locale(Locale(identifier: language))))
                .font(.headline)
            Spacer()
            Button { moveMonth(1) } label: { Image(systemName: "chevron.right") }
        }
        .padding(.horizontal)
    }

    private var weekGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 6) {
            ForEach(weekdayNames, id: \.self) {
                Text($0).font(.caption).foregroundStyle(ink.opacity(0.72))
            }
            ForEach(Array(dayCells.enumerated()), id: \.offset) { _, day in
                if let day { dayCell(day) } else { Color.clear.frame(height: 40) }
            }
        }
        .padding(.horizontal)
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
        let hasEvent = events.contains { calendar.isDate($0.startDate, inSameDayAs: day) }

        return Button { selectedDate = day } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: day))")
                    .frame(width: 32, height: 32)
                    .background(isSelected ? theme.accentColor : Color.clear, in: Circle())
                    .foregroundStyle(isSelected ? Color.white : ink)
                Circle()
                    .fill(hasEvent ? theme.accentColor : Color.clear)
                    .frame(width: 5, height: 5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - 동작들

    private func moveMonth(_ delta: Int) {
        if let moved = calendar.date(byAdding: .month, value: delta, to: monthAnchor) {
            monthAnchor = moved
        }
    }

    private func deleteEvents(at offsets: IndexSet) {
        for index in offsets {
            let event = eventsOnSelectedDay[index]
            NotificationService.cancel(for: event)
            context.delete(event)
        }
    }
}
