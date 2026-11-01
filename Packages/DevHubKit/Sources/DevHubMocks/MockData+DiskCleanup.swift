import Foundation
import DevHubDomain

extension MockData {
    package static let diskCleanupItems: [DiskCleanupItem] = [
        DiskCleanupItem(id: "staleDerivedData", kind: .staleDerivedData, paths: ["/Users/alex/Library/Developer/Xcode/DerivedData/OldApp-abc"], count: 4),
        DiskCleanupItem(
            id: "derivedData:/Users/alex/Library/Developer/Xcode/DerivedData/ExampleApp-def",
            kind: .derivedData,
            name: "ExampleApp.xcworkspace",
            detail: "/Users/alex/Developer/example-app/ExampleApp.xcworkspace",
            paths: ["/Users/alex/Library/Developer/Xcode/DerivedData/ExampleApp-def"]
        ),
        DiskCleanupItem(
            id: "derivedData:/Users/alex/Library/Developer/Xcode/DerivedData/ExampleWidget-ghi",
            kind: .derivedData,
            name: "ExampleWidget.xcodeproj",
            detail: "/Users/alex/Developer/example-widget/ExampleWidget.xcodeproj",
            paths: ["/Users/alex/Library/Developer/Xcode/DerivedData/ExampleWidget-ghi"]
        ),
        DiskCleanupItem(id: "archives", kind: .archives, paths: ["/Users/alex/Library/Developer/Xcode/Archives/2026-10-01"], count: 6),
        DiskCleanupItem(id: "deviceSupport", kind: .deviceSupport, paths: ["/Users/alex/Library/Developer/Xcode/iOS DeviceSupport/18.6 (22G86)"], count: 3),
        DiskCleanupItem(id: "swiftPMCache", kind: .swiftPMCache, paths: ["/Users/alex/Library/Caches/org.swift.swiftpm"]),
        DiskCleanupItem(id: "unavailableSimulators", kind: .unavailableSimulators, count: 2, size: 3_200_000_000),
        DiskCleanupItem(
            id: "runtime:4B1E1916",
            kind: .simulatorRuntime,
            name: "iOS 26.4",
            detail: "23E244",
            size: 8_485_747_282,
            lastUsed: Date(timeIntervalSince1970: 1_776_000_000),
            runtimeID: "4B1E1916"
        ),
        DiskCleanupItem(
            id: "runtime:6D0773D6",
            kind: .simulatorRuntime,
            name: "iOS 18.6",
            detail: "22G86",
            size: 8_838_255_185,
            lastUsed: Date(timeIntervalSince1970: 1_761_000_000),
            runtimeID: "6D0773D6"
        ),
    ]

    package static let diskCleanupSizes: [DiskCleanupItem.ID: Int64] = [
        "staleDerivedData": 12_400_000_000,
        "derivedData:/Users/alex/Library/Developer/Xcode/DerivedData/ExampleApp-def": 9_100_000_000,
        "derivedData:/Users/alex/Library/Developer/Xcode/DerivedData/ExampleWidget-ghi": 1_300_000_000,
        "archives": 4_600_000_000,
        "deviceSupport": 11_200_000_000,
        "swiftPMCache": 820_000_000,
    ]
}
