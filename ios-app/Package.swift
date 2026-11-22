// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VN-Sign",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "VNSignKit",
            targets: ["VNSignKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "VNSignKit",
            path: "VN-Sign",
            exclude: [
                "Info.plist"
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)
