// ============================================================
// 📄 HaruWidget.swift  —  홈 화면 · 잠금 화면 위젯
// ------------------------------------------------------------
// 이 파일은 위젯 익스텐션 Target에만 넣어요.
// ============================================================

import WidgetKit
import SwiftUI

struct HaruEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot
}

struct HaruProvider: TimelineProvider {
    func placeholder(in context: Context) -> HaruEntry {
        HaruEntry(date: .now,
                  snapshot: WidgetSnapshot(todoTitles: ["할 일 예시"],
                                           eventLines: ["09:00 일정 예시"],
                                           updatedAt: .now))
    }

    func getSnapshot(in context: Context, completion: @escaping (HaruEntry) -> Void) {
        completion(HaruEntry(date: .now, snapshot: WidgetSnapshot.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<HaruEntry>) -> Void) {
        let entry = HaruEntry(date: .now, snapshot: WidgetSnapshot.load())
        let next = Calendar.current.date(byAdding: .minute, value: 30, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(next)))
    }
}

struct HaruWidgetView: View {
    @Environment(.widgetFamily) private var family
    let entry: HaruEntry

    var body: some View {
        let snapshot = entry.snapshot
        let todos = snapshot.isFresh ? snapshot.todoTitles : []
        let events = snapshot.isFresh ? snapshot.eventLines : []

        switch family {
        case .accessoryInline:
            Text("✅ 남은 할 일 \(todos.count)개")

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
                ForEach(Array(todos.prefix(2).enumerated()), id: \.offset) { _, title in
                    Text("• \(title)").font(.caption).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

        default:
            VStack(alignment: .leading, spacing: 6) {
                Text("오늘").font(.headline)

                if !snapshot.isFresh {
                    Text("앱을 열어 새로고침해 주세요")
                        .font(.caption).foregroundStyle(.secondary)
                } else if todos.isEmpty && events.isEmpty {
                    Text("오늘은 할 일이 없어요 🎉")
                        .font(.caption).foregroundStyle(.secondary)
                }

                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, line in
                    Text("🗓 \(line)").font(.caption).lineLimit(1)
                }

                ForEach(Array(todos.prefix(family == .systemSmall ? 2 : 4).enumerated()),
                        id: \.offset) { _, title in
                    Text("☐ \(title)").font(.caption).lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

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
