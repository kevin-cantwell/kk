// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KK",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "KK",
            path: "Sources/KK"
        ),
        .testTarget(
            name: "KKTests",
            dependencies: ["KK"],
            path: "Tests/KKTests",
            swiftSettings: [
                .unsafeFlags(["-F/Library/Developer/CommandLineTools/Library/Developer/Frameworks"]),
            ],
            linkerSettings: [
                .unsafeFlags(["-F/Library/Developer/CommandLineTools/Library/Developer/Frameworks",
                              "-Xlinker", "-rpath", "-Xlinker", "/Library/Developer/CommandLineTools/Library/Developer/Frameworks"]),
            ]
        ),
    ]
)
