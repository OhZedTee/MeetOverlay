// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "MeetOverlay",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "MeetOverlayCore", targets: ["MeetOverlayCore"]),
        .executable(name: "MeetOverlayApp", targets: ["MeetOverlayApp"])
    ],
    targets: [
        .target(name: "MeetOverlayCore"),
        .executableTarget(
            name: "MeetOverlayApp",
            dependencies: ["MeetOverlayCore"]
        ),
        .testTarget(
            name: "MeetOverlayCoreTests",
            dependencies: ["MeetOverlayCore"]
        )
    ]
)
