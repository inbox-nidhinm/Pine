import AppKit
import Carbon

// UserDefaults-backed settings shared between AppKit and SwiftUI layers.

enum AppSettings {
    static let hotKeyCodeKey = "hotKeyCode"
    static let hotKeyModifiersKey = "hotKeyModifiers"
    static let uppercaseHexKey = "uppercaseHex"
    static let includeHashKey = "includeHash"

    static let shortcutChanged = Notification.Name("NiramShortcutChanged")

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            hotKeyCodeKey: kVK_ANSI_C,
            hotKeyModifiersKey: cmdKey | shiftKey,
            uppercaseHexKey: true,
            includeHashKey: true,
        ])
    }

    static var hotKeyCode: UInt32 {
        get { UInt32(UserDefaults.standard.integer(forKey: hotKeyCodeKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: hotKeyCodeKey) }
    }

    static var hotKeyModifiers: UInt32 {
        get { UInt32(UserDefaults.standard.integer(forKey: hotKeyModifiersKey)) }
        set { UserDefaults.standard.set(Int(newValue), forKey: hotKeyModifiersKey) }
    }

    static var uppercaseHex: Bool {
        UserDefaults.standard.bool(forKey: uppercaseHexKey)
    }

    static var includeHash: Bool {
        UserDefaults.standard.bool(forKey: includeHashKey)
    }

    static func formatHex(_ color: NSColor) -> String {
        formatHex(color, uppercase: uppercaseHex, hash: includeHash)
    }

    static func formatHex(_ color: NSColor, uppercase: Bool, hash: Bool) -> String {
        let hex = uppercase ? color.hexRRGGBB : color.hexRRGGBB.lowercased()
        return hash ? "#\(hex)" : hex
    }
}

// MARK: - Shortcut display helpers

func modifierSymbols(forCarbonFlags flags: UInt32) -> String {
    var s = ""
    if flags & UInt32(controlKey) != 0 { s += "⌃" }
    if flags & UInt32(optionKey) != 0 { s += "⌥" }
    if flags & UInt32(shiftKey) != 0 { s += "⇧" }
    if flags & UInt32(cmdKey) != 0 { s += "⌘" }
    return s
}

func keyName(forKeyCode keyCode: UInt32) -> String {
    let names: [UInt32: String] = [
        0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C",
        9: "V", 11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
        18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 24: "=", 25: "9",
        26: "7", 27: "-", 28: "8", 29: "0", 30: "]", 31: "O", 32: "U", 33: "[",
        34: "I", 35: "P", 37: "L", 38: "J", 39: "'", 40: "K", 41: ";", 42: "\\",
        43: ",", 44: "/", 45: "N", 46: "M", 47: ".", 50: "`",
        36: "↩", 48: "⇥", 49: "Space", 51: "⌫", 53: "⎋",
        123: "←", 124: "→", 125: "↓", 126: "↑",
        122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
        98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
    ]
    return names[keyCode] ?? "Key \(keyCode)"
}

func shortcutDescription(keyCode: UInt32, carbonModifiers: UInt32) -> String {
    modifierSymbols(forCarbonFlags: carbonModifiers) + keyName(forKeyCode: keyCode)
}

func carbonFlags(from flags: NSEvent.ModifierFlags) -> UInt32 {
    var m: UInt32 = 0
    if flags.contains(.command) { m |= UInt32(cmdKey) }
    if flags.contains(.shift) { m |= UInt32(shiftKey) }
    if flags.contains(.option) { m |= UInt32(optionKey) }
    if flags.contains(.control) { m |= UInt32(controlKey) }
    return m
}
