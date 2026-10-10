// ============================================================
// 📄 WidgetSyncService.swift  —  위젯에 "앞으로 7일 소식" 전달하기
// ------------------------------------------------------------
// 할 일/일정이 바뀔 때마다 MainTabView가 이 파일을 불러요.
//  1) 오늘부터 7일치 할 일·일정을 쪽지(WidgetSnapshot)로 정리해 공용 서랍에 넣고
//  2) 위젯에게 "화면 새로 그려!" 하고 알려줘요.
// ============================================================

import Foundation
import WidgetKit

enum WidgetSyncService {

    static func update(todos: [TodoItem], events: [CalendarEvent]) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: .now)
        let windowEnd = calendar.date(byAdding: .day, value: 8, to: startOfToday)
            ?? startOfToday.addingTimeInterval(8 * 86_400)

        // 오늘부터 7일 안의 할 일 + 어제까지 못 끝낸 할 일
        let todoItems = todos
            .filter { $0.dueDate < windowEnd && ($0.dueDate >= startOfToday || !$0.isDone) }
            .map { WidgetSnapshot.Todo(title: $0.title, dueDate: $0.dueDate, isDone: $0.isDone) }

        let eventItems = events
            .filter { $0.endDate > startOfToday && $0.startDate < windowEnd }
            .map { WidgetSnapshot.Event(title: $0.title, start: $0.startDate,
                                        end: $0.endDate, location: $0.location) }

        WidgetSnapshot(todos: todoItems, events: eventItems, updatedAt: .now).save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// 계정을 삭제할 때 위젯 내용도 비워요.
    static func clear() {
        WidgetSnapshot.clear()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
