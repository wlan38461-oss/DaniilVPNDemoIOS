import SwiftUI
import UIKit

private let REGIONAL_INDICATOR_BASE: UInt32 = 0x1F1E6 // 'A'
private let REGIONAL_INDICATOR_LAST: UInt32 = 0x1F1FF // 'Z'

/// Finds a leading flag-emoji pair (two "regional indicator" scalars) in
/// [text] and returns (2-letter code in lowercase, or nil; the remaining
/// text with the flag and extra whitespace stripped).
func extractFlagCode(_ text: String) -> (code: String?, remainder: String) {
    let trimmed = String(text.drop(while: { $0 == " " }))
    let scalars = Array(trimmed.unicodeScalars)
    guard scalars.count >= 2 else { return (nil, text) }

    let v1 = scalars[0].value
    let v2 = scalars[1].value
    guard (REGIONAL_INDICATOR_BASE...REGIONAL_INDICATOR_LAST).contains(v1),
          (REGIONAL_INDICATOR_BASE...REGIONAL_INDICATOR_LAST).contains(v2) else {
        return (nil, text)
    }

    let letter1 = Character(UnicodeScalar(v1 - REGIONAL_INDICATOR_BASE + UInt32(UnicodeScalar("A").value))!)
    let letter2 = Character(UnicodeScalar(v2 - REGIONAL_INDICATOR_BASE + UInt32(UnicodeScalar("A").value))!)
    let code = "\(letter1)\(letter2)".lowercased()

    var rest = String(String.UnicodeScalarView(scalars.dropFirst(2)))
    while rest.first == " " { rest.removeFirst() }
    return (code, rest)
}

/// Rounded-square (or circular, if [circular]) flag badge for a 2-letter
/// country code, backed by the SVG images bundled in Assets.xcassets.
/// Falls back to a plain text badge with the code if no matching asset
/// exists (e.g. for a country not in the bundled demo set).
struct FlagBadge: View {
    let code: String?
    let size: CGFloat
    var circular: Bool = false

    var body: some View {
        if let code, let uiImage = UIImage(named: code) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size, height: size)
                .clipShape(circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.22)))
        } else if let code {
            let shape = circular ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: size * 0.22))
            Text(code.uppercased())
                .font(.system(size: size * 0.33, weight: .bold))
                .frame(width: size, height: size)
                .background(Color.accentColor.opacity(0.18))
                .clipShape(shape)
        } else {
            EmptyView()
        }
    }
}

/// Type-erased Shape, since `circular ? Circle() : RoundedRectangle(...)`
/// doesn't type-check directly (different concrete Shape types).
struct AnyShape: Shape {
    private let pathBuilder: (CGRect) -> Path
    init<S: Shape>(_ shape: S) { pathBuilder = { rect in shape.path(in: rect) } }
    func path(in rect: CGRect) -> Path { pathBuilder(rect) }
}
