// ============================================================
// 📄 HaruWidget.swift  —  홈 화면 · 잠금 화면 위젯
// ------------------------------------------------------------
// 앱이 공용 서랍에 넣어 둔 "앞으로 7일치 쪽지(WidgetSnapshot)"를 읽어서 보여줘요.
// 지원하는 모양
//   · 홈 화면: 작은 위젯(systemSmall), 중간 위젯(systemMedium)
//   · 잠금 화면: 원형, 직사각형, 한 줄
//
// [고객 리뷰 "위젯에 오늘 할 일이 안 떠요" 수정]
//   위젯은 아래 시각마다 스스로 화면을 새로 그려요. (앱을 열지 않아도!)
//     · 지금 · 오늘 일정이 시작/끝나는 시각 · 자정(날짜가 바뀌는 순간)
//   그래서 자정이 지나면 새 날의 할 일이 자동으로 나타나고, 끝난 일정은 사라져요.
//
// ⚠️ 이 파일은 '위젯 익스텐션(HaruWidget)' 타깃에만 넣어요.
// ============================================================

import WidgetKit
import SwiftUI

// 위젯이 그릴 "한 장면"의 재료
struct HaruEntry: TimelineEntry {
    let date: Date                 // 이 장면이 보이기 시작하는 시각
    let snapshot: WidgetSnapshot   // 앱이 넣어 둔 7일치 쪽지
}

// 위젯에게 "언제, 어떤 장면을 그릴지" 알려주는 담당
struct HaruProvider: TimelineProvider {

    func placeholder(in context: Context) -> HaruEntry {
        let now = Date.now
        let sample = WidgetSnapshot(
            todos: [WidgetSnapshot.Todo(title: "할 일 예시", dueDate: now, isDone: false)],
            events: [WidgetSnapshot.Event(title: "일정 예시",
                                          start: now.addingTimeInterval(3600),
                                          end: now.addingTimeInterval(7200),
                                          location: "")],
            updatedAt: now)
        return HaruEntry(date: now, snapshot: sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (HaruEntry) -> Void) {
        completion(HaruEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HaruEntry>) -> Void) {
        let snapshot = WidgetSnapshot.load()
        let calendar = Calendar.current
        let now = Date.now
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now.addingTimeInterval(86_400)
        let midnight = calendar.startOfDay(for: tomorrow)

        // 장면이 바뀌는 시각들: 지금, 일정 시작/끝, 자정
        var moments: Set<Date> = [now, midnight]
        for event in snapshot.events {
            for moment in [event.start, event.end] where moment > now && moment < midnight {
                moments.insert(moment)
            }
        }

        let entries = moments.sorted().prefix(20).map { HaruEntry(date: $0, snapshot: snapshot) }
        let reloadAt = entries.last?.date ?? midnight
        completion(Timeline(entries: Array(entries), policy: .after(reloadAt)))
    }
}

// 위젯 모양
struct HaruWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: HaruEntry

    var body: some View {
        let snapshot = entry.snapshot
        // 이 장면의 시각(entry.date) 기준으로 '오늘 것'을 골라요.
        let todos = snapshot.remainingTodos(at: entry.date)
        let events = snapshot.upcomingEvents(at: entry.date)

        switch family {

        case .accessoryInline:
            Text(snapshot.hasSynced ? "✅ 남은 할 일 \(todos.count)개" : "앱을 한 번 열어 주세요")

        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Text("\(todos.count)").font(.title2.bold())
                    Text("할 일").font(.caption2)
                }
            }

        case .accessoryRectangular:
            VStack(alignment: .leading, spacing: 2) {
                Text("오늘 할 일 \(todos.count)개").font(.headline)
                if !snapshot.hasSynced {
                    Text("앱을 한 번 열어 주세요").font(.caption)
                }
                ForEach(Array(todos.prefix(2).enumerated()), id: \.offset) { _, todo in
                    Text("• \(todo.title)").font(.caption).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default: // 홈 화면 작은/중간 위젯
            VStack(alignment: .leading, spacing: 6) {
                Text("오늘").font(.headline)

                if !snapshot.hasSynced {
                    Text("앱을 한 번 열어 주세요")
                        .font(.caption).foregroundStyle(.secondary)
                } else if todos.isEmpty && events.isEmpty {
                    Text("오늘은 할 일이 없어요 🎉")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, event in
                    Text("🗓 \(event.start.formatted(.dateTime.hour().minute())) \(event.title)")
                        .font(.caption).lineLimit(1)
                }
                ForEach(Array(todos.prefix(family == .systemSmall ? 2 : 4).enumerated()),
                        id: \.offset) { _, todo in
                    Text("☐ \(todo.title)").font(.caption).lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// 위젯 등록 (위젯 목록에 어떤 이름으로 나올지)
@main
struct HaruWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "HaruWidget", provider: HaruProvider()) { entry in
            HaruWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("오늘의 할 일")
        .description("오늘 일정과 할 일을 홈 화면·잠금 화면에서 바로 확인해요")
        .supportedFamilies([.systemSmall, .systemMedium,
                            .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
