// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Niram",
    platforms: [.macOS(.v14)],
    targets: [
        // The fonts, the grain and Info.plist live in Resources/ at the top and
        // are put into the app by make-app.sh, not declared here: SwiftPM's
        // resource bundle would sit at the app's root, where signing refuses it.
        .executableTarget(
            name: "Niram",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
        .testTarget(name: "NiramTests", dependencies: ["Niram"]),
    ]
)
