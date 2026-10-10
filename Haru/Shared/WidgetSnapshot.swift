// ============================================================
// 📄 WidgetSnapshot.swift  —  앱과 위젯이 주고받는 "앞으로 7일치 쪽지"
// ------------------------------------------------------------
// 위젯은 앱과 따로 움직이는 작은 프로그램이라 앱의 저장소를 바로 못 봐요.
// 그래서 앱이 쪽지를 공용 서랍(App Group)에 넣어 두고, 위젯이 꺼내 읽어요.
//
// [v1.0에서 바뀐 점]  ← 고객 리뷰 "위젯에 오늘 할 일이 안 떠요" 수정
//  - 예전: '오늘' 것만 적은 쪽지 → 날짜가 바뀌면 낡은 쪽지가 되어 위젯이 텅 비었어요.
//  - 지금: 앞으로 7일치를 날짜와 함께 적어 두고, 위젯이 '그때그때 오늘 것'을 골라요.
//          그래서 앱을 안 열어도 자정에 위젯이 알아서 새 날로 바뀌어요.
//
// ⚠️ 이 파일은 '앱'과 '위젯' 두 곳 모두에 체크해서 넣어야 해요.
// ============================================================

import Foundation

struct WidgetSnapshot: Codable {

    struct Todo: Codable {
        var title: String
        var dueDate: Date
        var isDone: Bool
    }

    struct Event: Codable {
        var title: String
        var start: Date
        var end: Date
        var location: String
    }

    var todos: [Todo]
    var events: [Event]
    var updatedAt: Date

    private static let storageKey = "widgetSnapshot.v2"

    // MARK: - 오늘 것만 고르는 규칙 (위젯이 그때그때 사용)

    /// 오늘 할 일 = 오늘 날짜인 것 + 어제까지 못 끝낸 것 (앱의 '오늘' 화면과 같은 규칙)
    func todayTodos(at now: Date = .now) -> [Todo] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        return todos
            .filter { calendar.isDate($0.dueDate, inSameDayAs: now) || (!$0.isDone && $0.dueDate < startOfToday) }
            .sorted { $0.dueDate < $1.dueDate }
    }

    /// 아직 안 끝낸 오늘 할 일
    func remainingTodos(at now: Date = .now) -> [Todo] {
        todayTodos(at: now).filter { !$0.isDone }
    }

    /// 오늘 일정 중 아직 끝나지 않은 것 (이미 끝난 일정은 위젯에서 빠져요)
    func upcomingEvents(at now: Date = .now) -> [Event] {
        events
            .filter { Calendar.current.isDate($0.start, inSameDayAs: now) && $0.end > now }
            .sorted { $0.start < $1.start }
    }

    // MARK: - 서랍에 넣고 꺼내기

    /// 앱 그룹(공용 서랍)이 제대로 연결됐는지 확인해요. false면 Xcode 설정이 빠진 거예요.
    static var isAppGroupAvailable: Bool {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: SharedConfig.appGroupID) != nil
    }

    /// 한 번도 저장된 적이 없으면 false
    var hasSynced: Bool { updatedAt != .distantPast }

    static func load() -> WidgetSnapshot {
        guard let defaults = UserDefaults(suiteName: SharedConfig.appGroupID),
              let data = defaults.data(forKey: storageKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
        else {
            return WidgetSnapshot(todos: [], events: [], updatedAt: .distantPast)
        }
        return snapshot
    }

    func save() {
        guard let defaults = UserDefaults(suiteName: SharedConfig.appGroupID),
              let data = try? JSONEncoder().encode(self) else { return }
        defaults.set(data, forKey: Self.storageKey)
    }

    static func clear() {
        UserDefaults(suiteName: SharedConfig.appGroupID)?.removeObject(forKey: storageKey)
    }
}
