import SwiftUI

/// Same "key at night" identity as the Android app: deep indigo-navy
/// background with a warm brass/gold accent (idle/connecting), and a
/// separate emerald used only for "connected".
enum Theme {
    static func background(dark: Bool) -> Color {
        dark ? Color(red: 0x0A / 255, green: 0x0E / 255, blue: 0x1A / 255)
             : Color(red: 0xF6 / 255, green: 0xF4 / 255, blue: 0xEE / 255)
    }
    static func surfaceVariant(dark: Bool) -> Color {
        dark ? Color(red: 0x1B / 255, green: 0x21 / 255, blue: 0x38 / 255)
             : Color(red: 0xEC / 255, green: 0xE7 / 255, blue: 0xD8 / 255)
    }
    static func outline(dark: Bool) -> Color {
        dark ? Color(red: 0x2A / 255, green: 0x31 / 255, blue: 0x50 / 255)
             : Color(red: 0xDD / 255, green: 0xD6 / 255, blue: 0xC2 / 255)
    }
    static func accent(dark: Bool) -> Color {
        dark ? Color(red: 0xE3 / 255, green: 0xA7 / 255, blue: 0x37 / 255)
             : Color(red: 0xA9 / 255, green: 0x72 / 255, blue: 0x1A / 255)
    }
    static func onAccent(dark: Bool) -> Color {
        dark ? Color(red: 0x1A / 255, green: 0x12 / 255, blue: 0x00 / 255) : .white
    }
    static func connected(dark: Bool) -> Color {
        dark ? Color(red: 0x34 / 255, green: 0xD3 / 255, blue: 0x99 / 255)
             : Color(red: 0x0E / 255, green: 0x9A / 255, blue: 0x63 / 255)
    }
    static func errorColor(dark: Bool) -> Color {
        dark ? Color(red: 0xF8 / 255, green: 0x71 / 255, blue: 0x71 / 255)
             : Color(red: 0xDC / 255, green: 0x26 / 255, blue: 0x26 / 255)
    }
    static func textPrimary(dark: Bool) -> Color {
        dark ? Color(red: 0xF3 / 255, green: 0xF1 / 255, blue: 0xEC / 255)
             : Color(red: 0x1A / 255, green: 0x1B / 255, blue: 0x23 / 255)
    }
    static func textSecondary(dark: Bool) -> Color {
        dark ? Color(red: 0x8A / 255, green: 0x90 / 255, blue: 0xA6 / 255)
             : Color(red: 0x5D / 255, green: 0x60 / 255, blue: 0x72 / 255)
    }
}
