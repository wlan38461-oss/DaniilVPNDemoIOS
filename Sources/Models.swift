import Foundation

enum VpnState { case disconnected, connecting, connected, error }

enum PingState { case unknown, testing, ok, failed }

enum ProtocolPreference: String, CaseIterable { case vless = "VLESS", hysteria2 = "HYSTERIA2" }

struct ServerEntry: Identifiable, Hashable {
    let id = UUID()
    let index: Int
    let displayName: String
    let protocolName: String // "vless" or "hysteria2"

    var stableKey: String { "\(protocolName)_\(index)" }
}

struct PingInfo {
    let state: PingState
    let delayMs: Int?
}

struct LocationGroup: Identifiable {
    var id: String { key }
    let key: String
    let displayName: String
    let vlessEntry: ServerEntry?
    let hysteriaEntry: ServerEntry?
}

enum LocationLogic {
    static func buildGroups(hysteria: [ServerEntry], vless: [ServerEntry]) -> [LocationGroup] {
        var order: [String: LocationGroup] = [:]
        var keys: [String] = []
        for server in vless {
            let key = server.displayName
            if order[key] == nil { keys.append(key) }
            let existing = order[key]
            order[key] = LocationGroup(key: key, displayName: key, vlessEntry: server, hysteriaEntry: existing?.hysteriaEntry)
        }
        for server in hysteria {
            let key = server.displayName
            if order[key] == nil { keys.append(key) }
            let existing = order[key]
            order[key] = LocationGroup(key: key, displayName: existing?.displayName ?? key, vlessEntry: existing?.vlessEntry, hysteriaEntry: server)
        }
        return keys.compactMap { order[$0] }
    }

    static func resolve(group: LocationGroup?, protocolPref: ProtocolPreference) -> ServerEntry? {
        guard let group else { return nil }
        let preferred = protocolPref == .vless ? group.vlessEntry : group.hysteriaEntry
        let fallback = protocolPref == .vless ? group.hysteriaEntry : group.vlessEntry
        return preferred ?? fallback
    }

    static func groupState(_ group: LocationGroup, protocolPref: ProtocolPreference, ping: [String: PingInfo]) -> PingState {
        guard let resolved = resolve(group: group, protocolPref: protocolPref) else { return .unknown }
        return ping[resolved.stableKey]?.state ?? .unknown
    }

    static func resolveAuto(hysteria: [ServerEntry], vless: [ServerEntry], protocolPref: ProtocolPreference, ping: [String: PingInfo]) -> ServerEntry? {
        let pool = protocolPref == .vless ? vless : hysteria
        let ok = pool.filter { ping[$0.stableKey]?.state == .ok }
        if let best = ok.min(by: { (ping[$0.stableKey]?.delayMs ?? .max) < (ping[$1.stableKey]?.delayMs ?? .max) }) {
            return best
        }
        return pool.first
    }
}

/// Stand-in for the real subscription/ping machinery - visual-only demo,
/// nothing here touches the network.
enum DemoServers {
    static let locationNames = [
        "🇫🇮 Финляндия", "🇩🇪 Германия", "🇳🇱 Нидерланды", "🇺🇸 США",
        "🇦🇪 ОАЭ", "🇸🇬 Сингапур", "🇹🇷 Турция", "🇵🇱 Польша",
        "🇫🇷 Франция", "🇬🇧 Великобритания"
    ]

    static func generate() -> [ServerEntry] {
        var servers: [ServerEntry] = []
        for name in locationNames {
            servers.append(ServerEntry(index: servers.count, displayName: name, protocolName: "vless"))
            servers.append(ServerEntry(index: servers.count, displayName: name, protocolName: "hysteria2"))
        }
        return servers
    }
}

enum DemoPing {
    static func pingAll(_ servers: [ServerEntry]) async -> [String: PingInfo] {
        guard !servers.isEmpty else { return [:] }
        try? await Task.sleep(nanoseconds: 700_000_000)
        var result: [String: PingInfo] = [:]
        for server in servers {
            result[server.stableKey] = PingInfo(state: .ok, delayMs: Int.random(in: 18...140))
        }
        return result
    }
}
