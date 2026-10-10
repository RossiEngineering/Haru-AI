// ============================================================
// 📄 ChatModels.swift  —  AI 채팅 화면에서 쓰는 데이터 모양
// ------------------------------------------------------------
// ChatMessage  : 대화창의 말풍선 하나
// Proposal     : AI가 "이렇게 저장할까요?" 하고 내미는 '확인 카드' 한 장
// ProposalItem : 확인 카드 안의 항목 하나 (체크를 풀면 저장에서 빠져요)
// 이 값들은 대화 중에만 쓰고, 폰에 저장하지 않아요.
// ============================================================

import Foundation

struct ProposalItem: Identifiable {
    let id = UUID()
    let item: AIItem
    var isSelected = true
}

struct Proposal {
    enum Status { case waiting, saved, cancelled }

    var items: [ProposalItem]
    var status: Status = .waiting
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let isUser: Bool
    var text: String
    var proposal: Proposal? = nil
}
