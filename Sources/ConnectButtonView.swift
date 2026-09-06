import SwiftUI

struct ConnectButtonView: View {
    let state: VpnState
    let isSlowConnecting: Bool
    let isPinging: Bool
    let enabled: Bool
    let dark: Bool
    let onClick: () -> Void

    @State private var pulse = false

    private var buttonColor: Color {
        if isPinging { return Theme.accent(dark: dark) }
        switch state {
        case .disconnected: return Theme.surfaceVariant(dark: dark)
        case .connecting: return Theme.accent(dark: dark)
        case .connected: return Theme.connected(dark: dark)
        case .error: return Theme.errorColor(dark: dark)
        }
    }

    private var glowColor: Color {
        (state == .disconnected && !isPinging) ? Theme.accent(dark: dark) : buttonColor
    }

    private var glowAlpha: Double {
        (state == .disconnected && !isPinging) ? 0.10 : 0.28
    }

    private var showPulseRing: Bool { state == .connecting || isPinging }

    private var glyphColor: Color {
        if isPinging { return Theme.onAccent(dark: dark) }
        switch state {
        case .disconnected: return Theme.textSecondary(dark: dark)
        case .connecting: return Theme.onAccent(dark: dark)
        case .connected: return dark ? Color(red: 0, green: 0.157, blue: 0.102) : .white
        case .error: return dark ? Color(red: 0.165, green: 0.039, blue: 0.039) : .white
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [glowColor.opacity(glowAlpha), .clear], center: .center, startRadius: 0, endRadius: 130)
                )
                .frame(width: 260, height: 260)

            if showPulseRing {
                Circle()
                    .stroke(Theme.accent(dark: dark).opacity(pulse ? 0 : 0.4), lineWidth: 2)
                    .frame(width: pulse ? 270 : 200, height: pulse ? 270 : 200)
                    .animation(.easeOut(duration: 1.4).repeatForever(autoreverses: false), value: pulse)
                    .onAppear { pulse = true }
                    .onDisappear { pulse = false }
            }

            Circle()
                .fill(buttonColor)
                .frame(width: 190, height: 190)
                .overlay(glyph)
                .animation(.easeInOut(duration: 0.3), value: buttonColor)
                .onTapGesture { if enabled { onClick() } }
        }
        .frame(width: 260, height: 260)
    }

    @ViewBuilder
    private var glyph: some View {
        if isPinging {
            ProgressView().tint(glyphColor).scaleEffect(1.4)
        } else if state == .connecting && isSlowConnecting {
            KeyWarningGlyph(color: glyphColor).frame(width: 68, height: 68)
        } else {
            PowerGlyph(color: glyphColor).frame(width: 68, height: 68)
        }
    }
}

/// Hand-drawn power symbol (arc with a gap + a line through the gap).
struct PowerGlyph: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let strokeWidth = min(size.width, size.height) * 0.11
            let radius = (min(size.width, size.height) - strokeWidth) / 2
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let gapHalfAngle = 35.0

            var arc = Path()
            arc.addArc(
                center: center, radius: radius,
                startAngle: .degrees(-90 + gapHalfAngle),
                endAngle: .degrees(-90 + gapHalfAngle + (360 - gapHalfAngle * 2)),
                clockwise: false
            )
            context.stroke(arc, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            var line = Path()
            line.move(to: CGPoint(x: center.x, y: center.y - radius - strokeWidth * 0.7))
            line.addLine(to: CGPoint(x: center.x, y: center.y - radius * 0.05))
            context.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
        }
    }
}

/// Shown instead of PowerGlyph once CONNECTING has dragged on - a
/// hand-drawn key with an exclamation badge.
struct KeyWarningGlyph: View {
    let color: Color

    var body: some View {
        Canvas { context, size in
            let strokeWidth = min(size.width, size.height) * 0.10
            let bowRadius = min(size.width, size.height) * 0.20
            let bowCenter = CGPoint(x: bowRadius + strokeWidth * 1.2, y: size.height * 0.60)

            var bow = Path()
            bow.addArc(center: bowCenter, radius: bowRadius, startAngle: .degrees(0), endAngle: .degrees(360), clockwise: false)
            context.stroke(bow, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth))

            let shaftEndX = size.width * 0.62
            var shaft = Path()
            shaft.move(to: CGPoint(x: bowCenter.x + bowRadius, y: bowCenter.y))
            shaft.addLine(to: CGPoint(x: shaftEndX, y: bowCenter.y))
            context.stroke(shaft, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            var tooth1 = Path()
            tooth1.move(to: CGPoint(x: shaftEndX - strokeWidth * 0.9, y: bowCenter.y))
            tooth1.addLine(to: CGPoint(x: shaftEndX - strokeWidth * 0.9, y: bowCenter.y + bowRadius * 0.8))
            context.stroke(tooth1, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth * 0.8, lineCap: .round))

            var tooth2 = Path()
            tooth2.move(to: CGPoint(x: shaftEndX + strokeWidth * 0.5, y: bowCenter.y))
            tooth2.addLine(to: CGPoint(x: shaftEndX + strokeWidth * 0.5, y: bowCenter.y + bowRadius * 0.55))
            context.stroke(tooth2, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth * 0.8, lineCap: .round))

            let exX = size.width * 0.84
            let exTopY = size.height * 0.04
            let exBottomY = size.height * 0.38
            var exLine = Path()
            exLine.move(to: CGPoint(x: exX, y: exTopY))
            exLine.addLine(to: CGPoint(x: exX, y: exBottomY))
            context.stroke(exLine, with: .color(color), style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

            var dot = Path()
            dot.addEllipse(in: CGRect(x: exX - strokeWidth * 0.6, y: exBottomY + strokeWidth * 1.1, width: strokeWidth * 1.2, height: strokeWidth * 1.2))
            context.fill(dot, with: .color(color))
        }
    }
}
