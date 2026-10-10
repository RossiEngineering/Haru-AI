// ============================================================
// 📄 BriefingService.swift  —  아침 브리핑 · 저녁 일기 알림
// ------------------------------------------------------------
// ☀️ 아침 브리핑: 매일 정한 시각에 "오늘 일정 2개 · 할 일 3개, 첫 일정: 09:30 회의"
//    처럼 오늘 요약을 알려줘요.
//    알림 글은 미리 만들어 두는 거라서, 앞으로 7일치를 각각 예약해요.
//    (할 일/일정이 바뀌면 자동으로 다시 예약돼요)
// 🌙 저녁 일기 알림: 매일 정한 시각에 "오늘 하루 어땠나요?" 하고 일기를 권해요.
// ============================================================

import Foundation
import UserNotifications

enum BriefingService {

    // 알림 하나를 만들 재료. SwiftData 데이터는 다른 작업 줄로 못 넘기기 때문에
    // 필요한 값만 복사해서 담아요.
    private struct Plan: Sendable {
        let id: String
        let title: String
        let body: String
        let components: DateComponents
        let repeats: Bool
    }

    /// 브리핑 알림을 전부 지우고 현재 데이터와 설정에 맞게 다시 예약해요.
    static func reschedule(todos: [TodoItem], events: [CalendarEvent],
                           morningEnabled: Bool, morningHour: Int,
                           eveningEnabled: Bool, eveningHour: Int) {
        var plans: [Plan] = []
        if morningEnabled {
            plans += morningPlans(todos: todos, events: events, hour: morningHour)
        }
        if eveningEnabled {
            plans.append(Plan(id: "haru.evening",
                              title: "🌙 오늘 하루 어땠나요?",
                              body: "일기장에서 오늘 한 일로 초안을 만들어 볼까요?",
                              components: DateComponents(hour: eveningHour, minute: 0),
                              repeats: true))
        }

        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests { pending in
            let old = pending.map(\.identifier)
                .filter { $0.hasPrefix("haru.briefing.") || $0 == "haru.evening" }
            center.removePendingNotificationRequests(withIdentifiers: old)

            for plan in plans {
                let content = UNMutableNotificationContent()
                content.title = plan.title
                content.body = plan.body
                content.sound = .default
                let trigger = UNCalendarNotificationTrigger(dateMatching: plan.components,
                                                            repeats: plan.repeats)
                center.add(UNNotificationRequest(identifier: plan.id, content: content, trigger: trigger))
            }
        }
    }

    /// 오늘부터 7일 동안, 날마다 다른 내용의 아침 브리핑을 만들어요.
    private static func morningPlans(todos: [TodoItem], events: [CalendarEvent], hour: Int) -> [Plan] {
        let calendar = Calendar.current
        let now = Date.now
        let today = calendar.startOfDay(for: now)
        var result: [Plan] = []

        for offset in 0..<7 {
            guard let day = calendar.date(byAdding: .day, value: offset, to: today),
                  let fireDate = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: day),
                  fireDate > now else { continue }   // 이미 지난 시각은 건너뛰어요

            let dayEvents = events
                .filter { calendar.isDate($0.startDate, inSameDayAs: day) }
                .sorted { $0.startDate < $1.startDate }
            let dayTodos = todos.filter {
                !$0.isDone && (calendar.isDate($0.dueDate, inSameDayAs: day)
                               || (offset == 0 && $0.dueDate < today))
            }

            var lines: [String] = []
            if dayEvents.isEmpty && dayTodos.isEmpty {
                lines.append("오늘은 비어 있어요. 여유로운 하루 보내세요 🙂")
            } else {
                lines.append("일정 \(dayEvents.count)개 · 할 일 \(dayTodos.count)개")
                if let first = dayEvents.first {
                    lines.append("첫 일정: \(first.startDate.formatted(.dateTime.hour().minute())) \(first.title)")
                }
                if let todo = dayTodos.first {
                    lines.append("할 일: \(todo.title)")
                }
            }

            result.append(Plan(id: "haru.briefing.\(offset)",
                               title: "☀️ 오늘의 하루",
                               body: lines.joined(separator: "\n"),
                               components: calendar.dateComponents([.year, .month, .day, .hour, .minute],
                                                                   from: fireDate),
                               repeats: false))
        }
        return result
    }
}
