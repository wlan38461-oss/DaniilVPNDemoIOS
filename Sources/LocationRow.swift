import SwiftUI

struct LocationRow: View {
    let row: LocationRowState
    let isSelected: Bool
    let dark: Bool
    let protocolPref: ProtocolPreference

    private var protocolLabel: String? {
        guard let p = row.protocolName else { return nil }
        let base = p == "hysteria2" ? "HYSTERIA2" : "VLESS"
        if let ms = row.delayMs { return "\(base) · \(ms)мс" }
        return base
    }

    private var pingSymbol: (String, Color) {
        switch row.pingState {
        case .ok: return ("✓", Theme.connected(dark: dark))
        case .failed: return ("✗", Theme.errorColor(dark: dark))
        case .testing, .unknown: return ("…", Theme.textSecondary(dark: dark))
        }
    }

    private var flagAndName: (code: String?, name: String) {
        extractFlagCode(row.displayName)
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(pingSymbol.0)
                .foregroundColor(pingSymbol.1)
                .font(.system(size: 17, weight: .semibold))
                .frame(width: 22)

            FlagBadge(code: flagAndName.code, size: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(flagAndName.name)
                    .foregroundColor(Theme.textPrimary(dark: dark))
                    .lineLimit(1)
                if let protocolLabel {
                    Text(protocolLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Theme.textSecondary(dark: dark))
                }
            }
            Spacer()
        }
        .padding(16)
        .background(row.isAuto ? Theme.accent(dark: dark).opacity(0.12) : Theme.surfaceVariant(dark: dark))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? Theme.accent(dark: dark) : (row.isAuto ? Theme.accent(dark: dark).opacity(0.45) : .clear), lineWidth: 1)
        )
    }
}
