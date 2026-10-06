import AppKit

extension NSColor {
    /// "RRGGBB" (uppercase, no hash) in sRGB.
    var hexRRGGBB: String {
        guard let rgb = usingColorSpace(.sRGB) else { return "000000" }
        let r = Int(round(rgb.redComponent * 255))
        let g = Int(round(rgb.greenComponent * 255))
        let b = Int(round(rgb.blueComponent * 255))
        return String(format: "%02X%02X%02X", r, g, b)
    }

    convenience init?(hexString: String) {
        var hex = hexString.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")
        guard hex.count == 6, let value = UInt32(hex, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        self.init(srgbRed: r, green: g, blue: b, alpha: 1)
    }

    /// WCAG relative luminance.
    var relativeLuminance: CGFloat {
        guard let rgb = usingColorSpace(.sRGB) else { return 0 }
        func channel(_ c: CGFloat) -> CGFloat {
            c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(rgb.redComponent)
            + 0.7152 * channel(rgb.greenComponent)
            + 0.0722 * channel(rgb.blueComponent)
    }

    static func contrastRatio(_ a: NSColor, _ b: NSColor) -> CGFloat {
        let la = a.relativeLuminance
        let lb = b.relativeLuminance
        let lighter = max(la, lb)
        let darker = min(la, lb)
        return (lighter + 0.05) / (darker + 0.05)
    }
}

extension NSColor {
    /// A typed hex code, taking Figma's short forms as Twine does: `0` is
    /// `000000`, `1a` is `1A1A1A`, `abc` is `AABBCC`. A hash is optional.
    convenience init?(typedHex typed: String) {
        var text = typed.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.hasPrefix("#") { text.removeFirst() }
        guard !text.isEmpty, text.allSatisfy(\.isHexDigit) else { return nil }
        switch text.count {
        case 1: text = String(repeating: text, count: 6)
        case 2: text = String(repeating: text, count: 3)
        case 3: text = text.map { "\($0)\($0)" }.joined()
        default: break
        }
        self.init(hexString: text)
    }
}

/// The WCAG 2 contrast levels Compare shows, with the ratio each needs.
enum ContrastLevel: CaseIterable {
    case aa, aaLarge, aaa

    var name: String {
        switch self {
        case .aa: "AA"
        case .aaLarge: "AA Large"
        case .aaa: "AAA"
        }
    }

    var needs: CGFloat {
        switch self {
        case .aa: 4.5
        case .aaLarge: 3
        case .aaa: 7
        }
    }

    var help: String {
        switch self {
        case .aa: "WCAG AA for body text: a contrast of at least 4.5 to 1."
        case .aaLarge: "WCAG AA for large text (18 pt, or 14 pt bold) and for icons and controls: at least 3 to 1."
        case .aaa: "WCAG AAA for body text: at least 7 to 1."
        }
    }

    func passes(_ ratio: CGFloat) -> Bool { ratio >= needs }
}

/// A contrast ratio to two places, cut rather than rounded, so a ratio just
/// short of a level (4.497) never reads as reaching it (4.50).
func shownRatio(_ ratio: CGFloat) -> String {
    String(format: "%.2f", (ratio * 100).rounded(.down) / 100)
}
