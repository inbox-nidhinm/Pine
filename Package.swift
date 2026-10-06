// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "Niram",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Niram",
            linkerSettings: [
                .linkedFramework("Carbon")
            ]
        ),
    ]
)
