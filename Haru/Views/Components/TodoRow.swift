// ============================================================
// 📄 TodoRow.swift  —  '할 일 한 줄' 모양
// ------------------------------------------------------------
// 오른쪽 체크박스를 누르면 완료/해제가 되고, 완료하면 글자에 취소선이 그어져요.
// 여러 화면에서 같은 모양으로 쓰려고 따로 빼 둔 부품이에요.
// ============================================================

import SwiftUI

struct TodoRow: View {
    @Bindable var todo: TodoItem   // @Bindable = 값이 바뀌면 화면도 같이 바뀌어요
    @AppStorage(AppSettings.textColorKey) private var textColor = AppSettings.defaultTextColor
    @AppStorage(AppSettings.textOpacityKey) private var textOpacity = AppSettings.defaultTextOpacity

    private var ink: Color { (AppearanceColor(rawValue: textColor) ?? .charcoal).color.opacity(textOpacity) }

    var body: some View {
        Button {
            todo.isDone.toggle()
        } label: {
            HStack(spacing: 12) {
                Text(todo.title)
                    .strikethrough(todo.isDone)
                    .foregroundStyle(todo.isDone ? ink.opacity(0.7) : ink)
                Spacer(minLength: 12)
                Image(systemName: todo.isDone ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(todo.isDone ? Color.green.opacity(textOpacity) : ink.opacity(0.72))
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(todo.title)
        .accessibilityValue(todo.isDone ? "완료" : "미완료")
    }
}
