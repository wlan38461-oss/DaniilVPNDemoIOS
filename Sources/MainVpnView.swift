import SwiftUI

struct MainVpnView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 72)

            ConnectButtonView(
                state: state.vpnState,
                isSlowConnecting: state.isSlowConnecting,
                isPinging: state.preConnectPinging,
                enabled: (state.locationRows.count > 1 || state.vpnState != .disconnected) && !state.preConnectPinging,
                dark: state.isDarkTheme,
                onClick: { state.connectFlow() }
            )

            Spacer().frame(height: 22)
            ConnectionTimerView(connectedAt: state.connectedAt, dark: state.isDarkTheme)
            Spacer().frame(height: 4)
            StatusLabel(vpnState: state.vpnState, preConnectPinging: state.preConnectPinging, locationName: state.statusLocationName, dark: state.isDarkTheme)
            Spacer().frame(height: 12)
            ProtocolToggle(selected: state.preferredProtocol, enabled: !state.preConnectPinging, dark: state.isDarkTheme) { state.selectProtocol($0) }

            Spacer().frame(height: 32)

            HStack {
                Text("Серверы")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Theme.textSecondary(dark: state.isDarkTheme))
                Spacer()
            }
            .padding(.horizontal, 24)
            Spacer().frame(height: 10)

            if state.locationRows.count <= 1 {
                Spacer()
                Text("Список пуст")
                    .foregroundColor(Theme.textSecondary(dark: state.isDarkTheme))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(state.locationRows) { row in
                            LocationRow(row: row, isSelected: row.key == state.effectiveKey, dark: state.isDarkTheme, protocolPref: state.preferredProtocol)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if state.vpnState != .connecting { state.selectedKey = row.key }
                                }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
    }
}

private struct ConnectionTimerView: View {
    let connectedAt: Date?
    let dark: Bool
    @State private var elapsed: Int = 0
    @State private var timer: Timer? = nil

    var body: some View {
        Text(formatted)
            .font(.system(size: 40, weight: .semibold, design: .monospaced))
            .foregroundColor(Theme.textPrimary(dark: dark))
            .onAppear { restart() }
            .onChange(of: connectedAt) { _ in restart() }
            .onDisappear { timer?.invalidate() }
    }

    private var formatted: String {
        let h = elapsed / 3600
        let m = (elapsed % 3600) / 60
        let s = elapsed % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    private func restart() {
        timer?.invalidate()
        guard let connectedAt else { elapsed = 0; return }
        elapsed = Int(Date().timeIntervalSince(connectedAt))
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsed = Int(Date().timeIntervalSince(connectedAt))
        }
    }
}

private struct StatusLabel: View {
    let vpnState: VpnState
    let preConnectPinging: Bool
    let locationName: String?
    let dark: Bool

    private var text: String {
        if preConnectPinging { return "Проверка серверов…" }
        switch vpnState {
        case .disconnected: return "Отключено"
        case .connecting: return "Подключение…"
        case .connected: return "Подключено"
        case .error: return "Ошибка"
        }
    }

    private var color: Color {
        if preConnectPinging { return Theme.accent(dark: dark) }
        switch vpnState {
        case .disconnected: return Theme.textSecondary(dark: dark)
        case .connecting: return Theme.accent(dark: dark)
        case .connected: return Theme.connected(dark: dark)
        case .error: return Theme.errorColor(dark: dark)
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(text).font(.system(size: 16, weight: .medium)).foregroundColor(color)
            if let locationName {
                let (code, name) = extractFlagCode(locationName)
                HStack(spacing: 6) {
                    FlagBadge(code: code, size: 18, circular: true)
                    Text(name)
                        .font(.system(size: 14))
                        .foregroundColor(Theme.textSecondary(dark: dark))
                }
            }
        }
    }
}

private struct ProtocolToggle: View {
    let selected: ProtocolPreference
    let enabled: Bool
    let dark: Bool
    let onSelect: (ProtocolPreference) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ProtocolPreference.allCases, id: \.self) { p in
                Text(p.rawValue)
                    .font(.system(size: 11, weight: .medium))
                    .padding(.horizontal, 16).padding(.vertical, 7)
                    .background(selected == p ? Theme.accent(dark: dark) : .clear)
                    .foregroundColor(selected == p ? Theme.onAccent(dark: dark) : Theme.textSecondary(dark: dark))
                    .clipShape(RoundedRectangle(cornerRadius: 17))
                    .onTapGesture { if enabled { onSelect(p) } }
            }
        }
        .padding(3)
        .background(Theme.surfaceVariant(dark: dark))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
