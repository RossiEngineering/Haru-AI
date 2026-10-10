// ============================================================
// 📄 TodoItem.swift  —  '할 일' 하나의 설계도
// ------------------------------------------------------------
// 할 일 = 제목 + 해야 하는 날 + 끝냈는지 여부
// 앱을 켜면 첫 화면에 "오늘 해야 할 일"이 나오는데,
// 그때 이 정보를 보고 오늘 것만 골라서 보여줘요.
// ============================================================

import Foundation
import SwiftData

@Model
final class TodoItem {
    var title: String      // 할 일 내용 (예: 우유 사기)
    var dueDate: Date      // 언제까지 할 건가요?
    var isDone: Bool       // true = 끝냈어요
    var createdAt: Date    // 만든 시각 (목록 순서를 맞출 때 사용)

    init(title: String, dueDate: Date = .now, isDone: Bool = false) {
        self.title = title
        self.dueDate = dueDate
        self.isDone = isDone
        self.createdAt = .now
    }
}
