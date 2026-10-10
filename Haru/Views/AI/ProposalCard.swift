// ============================================================
// 📄 ProposalCard.swift  —  AI의 "이렇게 저장할까요?" 확인 카드
// ------------------------------------------------------------
// AI가 찾아낸 일정/할 일을 바로 저장하지 않고 카드로 먼저 보여줘요.
//  · 항목을 누르면 체크가 풀려서 저장에서 뺄 수 있어요
//  · [저장] → 체크된 것만 저장   [취소] → 아무것도 저장하지 않음
// AI가 잘못 알아들어도 사용자가 마지막에 막을 수 있게 하는 안전장치예요.
// ============================================================

import SwiftUI

struct ProposalCard: View {
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity
    let proposal: Proposal
    let onToggle: (UUID) -> Void
    let onSave: () -> Void
    let onCancel: () -> Void

    private var selectedCount: Int { proposal.items.filter(\.isSelected).count }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("이렇게 저장할까요?")
                .font(.subheadline.bold())

            ForEach(proposal.items) { entry in
                Button { onToggle(entry.id) } label: {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: entry.isSelected ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(entry.isSelected ? (AppBackground(rawValue: background) ?? .system).accentColor : Color.secondary)
                        Image(systemName: entry.item.isEvent ? "calendar" : "checklist")
                            .foregroundStyle(ink.opacity(0.65))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.item.title ?? "")
                                .font(.body)
                            Text(detail(of: entry.item))
                                .font(.caption)
                                .foregroundStyle(ink.opacity(0.72))
                        }
                        Spacer(minLength: 0)
                    }
                }
                .buttonStyle(.plain)
                .disabled(proposal.status != .waiting)
            }

            switch proposal.status {
            case .waiting:
                HStack {
                    Button("취소", action: onCancel)
                        .buttonStyle(.bordered)
                    Button("저장 (\(selectedCount))", action: onSave)
                        .buttonStyle(.borderedProminent)
                        .disabled(selectedCount == 0)
                }
            case .saved:
                Text("✅ 저장했어요").font(.footnote).foregroundStyle(ink)
            case .cancelled:
                Text("저장하지 않았어요").font(.footnote).foregroundStyle(ink.opacity(0.72))
            }
        }
        .padding(14)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .padding(.trailing, 40)
    }

    /// 항목 아래 작은 글씨: 날짜·시간·장소
    private func detail(of item: AIItem) -> String {
        var parts: [String] = []
        if let date = item.startDate {
            parts.append(item.isEvent
                         ? date.formatted(.dateTime.month().day().weekday().hour().minute().locale(Locale(identifier: language)))
                         : date.formatted(.dateTime.month().day().weekday().locale(Locale(identifier: language))))
        } else {
            parts.append("날짜 없음 (오늘 할 일로 저장)")
        }
        if let place = item.location, !place.isEmpty { parts.append("📍 \(place)") }
        return parts.joined(separator: " · ")
    }

    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }
}
