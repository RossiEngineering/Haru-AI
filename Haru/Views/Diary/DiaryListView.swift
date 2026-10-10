// ============================================================
// 📄 DiaryListView.swift  —  일기장 목록 화면
// ------------------------------------------------------------
// 쓴 일기를 최신순으로 보여줘요. (날씨 이모지 · 날짜 · 글 미리보기 · 사진 썸네일)
//  - 일기를 누르면 수정 화면(DiaryEditorView)으로 이동
//  - 오른쪽 위 + 버튼으로 새 일기 쓰기
//  - 왼쪽으로 밀면 삭제
// ============================================================

import SwiftUI
import SwiftData

struct DiaryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \DiaryEntry.date, order: .reverse) private var entries: [DiaryEntry]
    @AppStorage(AppSettings.backgroundKey) private var background = AppSettings.defaultBackground
    @AppStorage(AppSettings.backgroundImageKey) private var backgroundImage = ""
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity
    private var theme: AppBackground { AppBackground(rawValue: background) ?? .system }

    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(entries) { entry in
                    NavigationLink {
                        DiaryEditorView(entry: entry)
                    } label: {
                        DiaryRow(entry: entry)
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(entries[index]) }
                }
            }
            .scrollContentBackground(.hidden)
            .background { AppBackgroundLayer(background: theme, imageData: Data(base64Encoded: backgroundImage)) }
            .listRowBackground(theme.rowColor)
            .foregroundStyle((AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity))
            .tint(theme.accentColor)
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("아직 일기가 없어요",
                                           systemImage: "book.closed",
                                           description: Text("오른쪽 위 + 버튼으로 오늘 하루를 기록해 보세요"))
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("일기장").foregroundStyle(Color.black)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingNew = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showingNew) {
                NavigationStack { DiaryEditorView(entry: nil) }
            }
        }
    }
}

// 목록의 '일기 한 줄' 모양 (이 파일 안에서만 쓰는 작은 부품)
private struct DiaryRow: View {
    let entry: DiaryEntry
    @AppStorage(AppSettings.languageKey) private var language = AppLanguage.korean.rawValue
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity

    var body: some View {
        HStack(spacing: 12) {
            if let data = entry.photoData, let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("\(entry.weather.emoji) \(entry.date.formatted(.dateTime.year().month().day().weekday().locale(Locale(identifier: language))))")
                    .font(.subheadline.bold())
                Text(entry.content.isEmpty ? "(내용 없음)" : entry.content)
                    .font(.footnote)
                    .foregroundStyle((AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity * 0.72))
                    .lineLimit(2)
            }
        }
    }
}
