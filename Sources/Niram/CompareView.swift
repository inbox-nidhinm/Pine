import SwiftUI
import AppKit

@MainActor
final class CompareModel: ObservableObject {
    @Published var colorA: NSColor = NSColor(hexString: "#1D1D1F") ?? .black
    @Published var colorB: NSColor = NSColor(hexString: "#F5F5F7") ?? .white
}

struct CompareView: View {
    @ObservedObject var model: CompareModel

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 1) {
                ColorPanel(
                    title: "Color 1",
                    color: Binding(get: { model.colorA }, set: { model.colorA = $0 })
                )
                ColorPanel(
                    title: "Color 2",
                    color: Binding(get: { model.colorB }, set: { model.colorB = $0 })
                )
            }

            Divider()
            ContrastBar(colorA: model.colorA, colorB: model.colorB)
        }
        .frame(width: 520, height: 340)
    }
}

private struct ColorPanel: View {
    let title: String
    @Binding var color: NSColor
    @State private var hexText: String = ""
    @State private var justCopied = false

    private var textColor: Color {
        color.relativeLuminance > 0.4 ? .black : .white
    }

    var body: some View {
        ZStack {
            Color(nsColor: color)

            VStack(spacing: 10) {
                Spacer()

                Text(AppSettings.formatHex(color))
                    .font(.system(size: 22, weight: .semibold, design: .monospaced))
                    .foregroundStyle(textColor)

                HStack(spacing: 8) {
                    Button {
                        pick()
                    } label: {
                        Label("Pick", systemImage: "eyedropper")
                    }

                    Button {
                        copy()
                    } label: {
                        Label(justCopied ? "Copied" : "Copy", systemImage: justCopied ? "checkmark" : "doc.on.doc")
                    }
                }
                .controlSize(.small)

                TextField("Hex", text: $hexText)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .multilineTextAlignment(.center)
                    .frame(width: 110)
                    .onSubmit {
                        if let parsed = NSColor(hexString: hexText) {
                            color = parsed
                        } else {
                            hexText = AppSettings.formatHex(color)
                        }
                    }

                Spacer()
            }
            .padding()

            VStack {
                HStack {
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(textColor.opacity(0.7))
                    Spacer()
                }
                Spacer()
            }
            .padding(10)
        }
        .onAppear { hexText = AppSettings.formatHex(color) }
        .onChange(of: color) { newValue in
            hexText = AppSettings.formatHex(newValue)
        }
    }

    private func pick() {
        NSColorSampler().show { picked in
            guard let picked else { return }
            DispatchQueue.main.async {
                color = picked
            }
        }
    }

    private func copy() {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(AppSettings.formatHex(color), forType: .string)
        justCopied = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            justCopied = false
        }
    }
}

private struct ContrastBar: View {
    let colorA: NSColor
    let colorB: NSColor

    var body: some View {
        let ratio = NSColor.contrastRatio(colorA, colorB)

        HStack(spacing: 12) {
            Text("Contrast")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(String(format: "%.2f : 1", ratio))
                .font(.system(.callout, design: .monospaced).weight(.semibold))

            Spacer()

            WCAGBadge(label: "AA", passes: ratio >= 4.5)
            WCAGBadge(label: "AA Large", passes: ratio >= 3.0)
            WCAGBadge(label: "AAA", passes: ratio >= 7.0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct WCAGBadge: View {
    let label: String
    let passes: Bool

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: passes ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundStyle(passes ? .green : .red)
            Text(label)
                .font(.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.quaternary, in: Capsule())
    }
}
