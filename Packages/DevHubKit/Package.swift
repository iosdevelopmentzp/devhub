// swift-tools-version: 6.2
import PackageDescription

let shared: [SwiftSetting] = [
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
]
let mainActor: [SwiftSetting] = shared + [.defaultIsolation(MainActor.self)]

let package = Package(
    name: "DevHubKit",
    platforms: [.macOS("26.4")],
    products: [.library(name: "DevHubComposition", targets: ["DevHubComposition"])],
    targets: [
        .target(name: "DevHubDomain", swiftSettings: shared),
        .target(name: "DevHubData", dependencies: ["DevHubDomain"], swiftSettings: shared),
        .target(name: "DevHubMocks", dependencies: ["DevHubDomain"], swiftSettings: shared),
        .target(name: "DevHubUI", swiftSettings: mainActor),
        .target(name: "DevHubPresentation", dependencies: ["DevHubDomain", "DevHubUI", "DevHubMocks"], swiftSettings: mainActor),
        .target(name: "DevHubComposition", dependencies: ["DevHubDomain", "DevHubData", "DevHubMocks", "DevHubPresentation"], swiftSettings: mainActor),
        .target(name: "DevHubTestSupport", dependencies: ["DevHubDomain"], swiftSettings: shared),
        .testTarget(name: "DevHubDomainTests", dependencies: ["DevHubDomain", "DevHubTestSupport"], swiftSettings: shared),
        .testTarget(name: "DevHubDataTests", dependencies: ["DevHubData", "DevHubMocks", "DevHubTestSupport"], swiftSettings: shared),
        .testTarget(name: "DevHubUITests", dependencies: ["DevHubUI"], swiftSettings: mainActor),
        .testTarget(name: "DevHubPresentationTests", dependencies: ["DevHubPresentation", "DevHubMocks", "DevHubTestSupport"], swiftSettings: mainActor),
    ]
)
