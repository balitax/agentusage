// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AgentUsage",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "AgentUsage", path: "Sources/AgentUsage"),
        .testTarget(name: "AgentUsageTests", dependencies: ["AgentUsage"], path: "Tests/AgentUsageTests"),
    ]
)
