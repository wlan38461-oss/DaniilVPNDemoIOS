import SwiftUI

struct KeyEntryView: View {
    @ObservedObject var state: AppState
    @State private var text: String = ""

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text("🔑").font(.system(size: 56))
            Text("Вставьте ключ")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(Theme.textPrimary(dark: state.isDarkTheme))

            TextField("dvpn://… или ссылка подписки", text: $text)
                .textFieldStyle(.plain)
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(Theme.surfaceVariant(dark: state.isDarkTheme))
                .clipShape(RoundedRectangle(cornerRadius: 28))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(Theme.outline(dark: state.isDarkTheme), lineWidth: 1)
                )
                .autocapitalization(.none)
                .disableAutocorrection(true)

            Button(action: {
                if !text.trimmingCharacters(in: .whitespaces).isEmpty {
                    state.unlockDemo()
                }
            }) {
                if state.loading {
                    ProgressView().tint(Theme.onAccent(dark: state.isDarkTheme))
                        .frame(maxWidth: .infinity, minHeight: 56)
                } else {
                    Text("Продолжить")
                        .font(.system(size: 15, weight: .medium))
                        .frame(maxWidth: .infinity, minHeight: 56)
                }
            }
            .background(Theme.accent(dark: state.isDarkTheme))
            .foregroundColor(Theme.onAccent(dark: state.isDarkTheme))
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .disabled(state.loading || text.trimmingCharacters(in: .whitespaces).isEmpty)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
