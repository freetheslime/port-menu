// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PortMenu",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "porter", targets: ["Port_Menu"])
    ],
    targets: [
        .executableTarget(
            name: "Port_Menu",
            path: "Porter",
            exclude: [
                "Porter.entitlements"
            ],
            resources: [
                .process("Assets.xcassets"),
                .copy("AppIconSource.icns")
            ]
        ),
        .testTarget(
            name: "PorterTests",
            dependencies: ["Port_Menu"],
            path: "PorterTests"
        )
    ]
)
