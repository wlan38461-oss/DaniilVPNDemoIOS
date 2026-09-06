import SwiftUI

private let kDarkTheme = "dark_theme"
private let kProtocol = "protocol_preference"
private let kUnlocked = "demo_unlocked"
private let AUTO_KEY = "auto"
private let SLOW_CONNECT_SECONDS: UInt64 = 5
private let FAKE_CONNECT_MIN_MS: UInt64 = 1400
private let FAKE_CONNECT_MAX_MS: UInt64 = 3200

enum Screen { case keyEntry, main, bypass }

struct LocationRowState: Identifiable {
    var id: String { key }
    let key: String
    let displayName: String
    let pingState: PingState
    let delayMs: Int?
    let protocolName: String?
    let isAuto: Bool
}

@MainActor
final class AppState: ObservableObject {
    @Published var isDarkTheme: Bool = UserDefaults.standard.object(forKey: kDarkTheme) as? Bool ?? true
    @Published var preferredProtocol: ProtocolPreference =
        ProtocolPreference(rawValue: UserDefaults.standard.string(forKey: kProtocol) ?? "") ?? .vless

    @Published var screen: Screen
    @Published var servers: [ServerEntry] = []
    @Published var selectedKey: String? = nil
    @Published var loading = false
    @Published var serverPickerOpen = false
    @Published var pingResults: [String: PingInfo] = [:]
    @Published var preConnectPinging = false

    @Published var vpnState: VpnState = .disconnected
    @Published var connectedAt: Date? = nil
    @Published var isSlowConnecting = false
    @Published var snackbar: String? = nil

    init() {
        let unlocked = UserDefaults.standard.bool(forKey: kUnlocked)
        screen = unlocked ? .main : .keyEntry
        if unlocked {
            servers = DemoServers.generate()
        }
    }

    func toggleTheme() {
        isDarkTheme.toggle()
        UserDefaults.standard.set(isDarkTheme, forKey: kDarkTheme)
    }

    func selectProtocol(_ p: ProtocolPreference) {
        preferredProtocol = p
        UserDefaults.standard.set(p.rawValue, forKey: kProtocol)
    }

    private func split() -> (hysteria: [ServerEntry], vless: [ServerEntry]) {
        (servers.filter { $0.protocolName == "hysteria2" }, servers.filter { $0.protocolName == "vless" })
    }

    var effectiveKey: String { selectedKey ?? AUTO_KEY }

    var locationRows: [LocationRowState] {
        let (hy, vl) = split()
        let groups = LocationLogic.buildGroups(hysteria: hy, vless: vl)
        let autoPool = preferredProtocol == .vless ? vl : hy
        let autoStates = autoPool.compactMap { pingResults[$0.stableKey]?.state }
        let autoState: PingState = autoStates.contains(.ok) ? .ok : (autoStates.isEmpty ? .unknown : (autoStates.allSatisfy { $0 == .failed } ? .failed : .unknown))
        let autoResolved = LocationLogic.resolveAuto(hysteria: hy, vless: vl, protocolPref: preferredProtocol, ping: pingResults)
        let autoDelay = autoResolved.flatMap { pingResults[$0.stableKey]?.delayMs }
        let autoRow = LocationRowState(key: AUTO_KEY, displayName: "🇪🇺 Авто ⚡", pingState: autoState, delayMs: autoDelay, protocolName: autoResolved?.protocolName, isAuto: true)

        let groupRows = groups.map { group -> LocationRowState in
            let resolved = LocationLogic.resolve(group: group, protocolPref: preferredProtocol)
            let delay = resolved.flatMap { pingResults[$0.stableKey]?.delayMs }
            return LocationRowState(
                key: group.key, displayName: group.displayName,
                pingState: LocationLogic.groupState(group, protocolPref: preferredProtocol, ping: pingResults),
                delayMs: delay, protocolName: resolved?.protocolName, isAuto: false
            )
        }
        return [autoRow] + groupRows
    }

    var statusLocationName: String? {
        locationRows.first(where: { $0.key == effectiveKey })?.displayName
    }

    func unlockDemo() {
        loading = true
        Task {
            try? await Task.sleep(nanoseconds: 700_000_000)
            servers = DemoServers.generate()
            selectedKey = AUTO_KEY
            UserDefaults.standard.set(true, forKey: kUnlocked)
            screen = .main
            loading = false
            await runPing()
        }
    }

    func runPing() async {
        guard !servers.isEmpty else { return }
        let result = await DemoPing.pingAll(servers)
        pingResults = result
    }

    func connectFlow() {
        if vpnState == .connected || vpnState == .connecting {
            vpnState = .disconnected
            connectedAt = nil
            return
        }
        guard !preConnectPinging else { return }
        Task {
            preConnectPinging = true
            await runPing()
            preConnectPinging = false

            let (hy, vl) = split()
            let entry: ServerEntry?
            if effectiveKey == AUTO_KEY {
                entry = LocationLogic.resolveAuto(hysteria: hy, vless: vl, protocolPref: preferredProtocol, ping: pingResults)
            } else {
                let group = LocationLogic.buildGroups(hysteria: hy, vless: vl).first { $0.key == effectiveKey }
                entry = LocationLogic.resolve(group: group, protocolPref: preferredProtocol)
            }
            guard entry != nil else {
                snackbar = "Нет доступных серверов"
                return
            }

            vpnState = .connecting
            let slowTask = Task {
                try? await Task.sleep(nanoseconds: SLOW_CONNECT_SECONDS * 1_000_000_000)
                if vpnState == .connecting { isSlowConnecting = true }
            }
            let waitMs = UInt64.random(in: FAKE_CONNECT_MIN_MS...FAKE_CONNECT_MAX_MS)
            try? await Task.sleep(nanoseconds: waitMs * 1_000_000)
            slowTask.cancel()
            isSlowConnecting = false
            vpnState = .connected
            connectedAt = Date()
        }
    }
}

struct RootView: View {
    @StateObject private var state = AppState()

    var body: some View {
        ZStack {
            Theme.background(dark: state.isDarkTheme).ignoresSafeArea()

            Group {
                switch state.screen {
                case .keyEntry:
                    KeyEntryView(state: state)
                case .main:
                    MainVpnView(state: state)
                case .bypass:
                    BypassAppsView(state: state)
                }
            }

            if state.screen != .bypass {
                VStack {
                    HStack {
                        Spacer()
                        TopCornerControls(state: state)
                    }
                    Spacer()
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
            }

            if let message = state.snackbar {
                VStack {
                    Spacer()
                    Text(message)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Theme.surfaceVariant(dark: state.isDarkTheme))
                        .foregroundColor(Theme.textPrimary(dark: state.isDarkTheme))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .padding(.bottom, 24)
                }
                .task {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                    state.snackbar = nil
                }
            }
        }
        .sheet(isPresented: $state.serverPickerOpen) {
            ServerPickerSheet(state: state)
        }
        .preferredColorScheme(state.isDarkTheme ? .dark : .light)
    }
}

private struct TopCornerControls: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 10) {
            if state.screen == .main {
                RoundIconButton(emoji: "🌐") { state.serverPickerOpen = true }
                RoundIconButton(emoji: "🛡️") { state.screen = .bypass }
                RoundIconButton(emoji: "🔑") { state.screen = .keyEntry }
            }
            RoundIconButton(emoji: state.isDarkTheme ? "☀️" : "🌙") { state.toggleTheme() }
        }
    }
}

private struct RoundIconButton: View {
    let emoji: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(emoji)
                .font(.system(size: 18))
                .frame(width: 44, height: 44)
                .background(Color.gray.opacity(0.18))
                .clipShape(Circle())
        }
    }
}

private struct ServerPickerSheet: View {
    @ObservedObject var state: AppState

    var body: some View {
        NavigationView {
            List(state.locationRows) { row in
                LocationRow(row: row, isSelected: row.key == state.effectiveKey, dark: state.isDarkTheme, protocolPref: state.preferredProtocol)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        state.selectedKey = row.key
                        state.serverPickerOpen = false
                    }
                    .listRowBackground(Theme.background(dark: state.isDarkTheme))
            }
            .listStyle(.plain)
            .navigationTitle("Выбор сервера")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Закрыть") { state.serverPickerOpen = false }
                }
            }
        }
    }
}
