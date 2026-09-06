import SwiftUI

private let kDomains = "direct_domains"
private let kIps = "direct_ips"

private let defaultDomains: Set<String> = [
    "sberbank.ru", "sber.ru", "tbank.ru", "tinkoff.ru", "vtb.ru", "alfabank.ru",
    "gosuslugi.ru", "nalog.ru", "mos.ru", "gibdd.ru",
    "vk.com", "ok.ru", "mail.ru", "yandex.ru", "ya.ru",
    "wildberries.ru", "ozon.ru", "avito.ru"
]
private let defaultIps: Set<String> = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16", "127.0.0.0/8"]

enum DirectRouting {
    static func getDomains() -> Set<String> {
        if let arr = UserDefaults.standard.array(forKey: kDomains) as? [String] { return Set(arr) }
        return defaultDomains
    }
    static func setDomains(_ domains: Set<String>) {
        UserDefaults.standard.set(Array(domains), forKey: kDomains)
    }
    static func getIps() -> Set<String> {
        if let arr = UserDefaults.standard.array(forKey: kIps) as? [String] { return Set(arr) }
        return defaultIps
    }
    static func setIps(_ ips: Set<String>) {
        UserDefaults.standard.set(Array(ips), forKey: kIps)
    }
}

struct BypassAppsView: View {
    @ObservedObject var state: AppState
    @State private var tab = 0

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 24)
            HStack {
                Button(action: { state.screen = .main }) {
                    Text("←")
                        .frame(width: 40, height: 40)
                        .background(Theme.surfaceVariant(dark: state.isDarkTheme))
                        .clipShape(Circle())
                        .foregroundColor(Theme.textPrimary(dark: state.isDarkTheme))
                }
                Text("Работает напрямую, без VPN")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(Theme.textPrimary(dark: state.isDarkTheme))
                Spacer()
            }
            .padding(.horizontal, 20)
            Spacer().frame(height: 16)

            Picker("", selection: $tab) {
                Text("Сайты").tag(0)
                Text("IP-адреса").tag(1)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 20)
            Spacer().frame(height: 16)

            if tab == 0 {
                EditableListView(
                    hint: "Домены (и их поддомены) идут напрямую, минуя VPN",
                    placeholder: "example.com",
                    dark: state.isDarkTheme,
                    initial: DirectRouting.getDomains(),
                    onChange: { DirectRouting.setDomains($0) }
                )
            } else {
                EditableListView(
                    hint: "IP или подсеть (например 1.2.3.4 или 1.2.3.0/24) идёт напрямую, минуя VPN",
                    placeholder: "1.2.3.4 или 1.2.3.0/24",
                    dark: state.isDarkTheme,
                    initial: DirectRouting.getIps(),
                    onChange: { DirectRouting.setIps($0) }
                )
            }
        }
    }
}

private struct EditableListView: View {
    let hint: String
    let placeholder: String
    let dark: Bool
    @State var initial: Set<String>
    let onChange: (Set<String>) -> Void

    @State private var input = ""
    @State private var items: Set<String> = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(hint)
                .font(.system(size: 13))
                .foregroundColor(Theme.textSecondary(dark: dark))

            HStack {
                TextField(placeholder, text: $input)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 14).padding(.vertical, 12)
                    .background(Theme.surfaceVariant(dark: dark))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .autocapitalization(.none)
                    .disableAutocorrection(true)

                Button(action: add) {
                    Text("+").font(.system(size: 22))
                        .frame(width: 48, height: 48)
                        .background(Theme.accent(dark: dark))
                        .foregroundColor(Theme.onAccent(dark: dark))
                        .clipShape(Circle())
                }
                .disabled(input.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if items.isEmpty {
                Spacer()
                HStack { Spacer(); Text("Список пуст").foregroundColor(Theme.textSecondary(dark: dark)); Spacer() }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 6) {
                        ForEach(items.sorted(), id: \.self) { entry in
                            HStack {
                                Text(entry).foregroundColor(Theme.textPrimary(dark: dark)).lineLimit(1)
                                Spacer()
                                Text("✕").foregroundColor(Theme.errorColor(dark: dark))
                                    .onTapGesture { remove(entry) }
                            }
                            .padding(.horizontal, 16).padding(.vertical, 12)
                            .background(Theme.surfaceVariant(dark: dark))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .onAppear { items = initial }
    }

    private func add() {
        let cleaned = input.trimmingCharacters(in: .whitespaces).lowercased()
        guard !cleaned.isEmpty else { return }
        items.insert(cleaned)
        onChange(items)
        input = ""
    }

    private func remove(_ entry: String) {
        items.remove(entry)
        onChange(items)
    }
}
