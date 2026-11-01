import Foundation
import DevHubDomain
import DevHubUI

enum DiskCleanupText {
    static func title(for item: DiskCleanupItem) -> String {
        switch item.kind {
        case .staleDerivedData: "DerivedData of deleted projects"
        case .derivedData: item.name ?? "DerivedData"
        case .unavailableSimulators: "Unavailable simulators"
        case .simulatorRuntime: item.name ?? "Simulator runtime"
        case .archives: "Archives"
        case .deviceSupport: "Device support files"
        case .swiftPMCache: "Swift Package Manager cache"
        case .cocoaPodsCache: "CocoaPods cache"
        }
    }

    static func operationTitle(for item: DiskCleanupItem) -> String {
        switch item.kind {
        case .derivedData: "Delete DerivedData of \(title(for: item))"
        case .simulatorRuntime: "Delete the \(title(for: item)) simulator runtime"
        default: "Delete \(title(for: item))"
        }
    }

    static func command(for item: DiskCleanupItem) -> String {
        switch item.kind {
        case .unavailableSimulators: "xcrun simctl delete unavailable"
        case .simulatorRuntime: "xcrun simctl runtime delete \(item.runtimeID ?? "")"
        default: "rm -rf " + (item.paths.count == 1 ? item.paths[0].abbreviatingHome : CountText.count(item.paths.count, "folder"))
        }
    }
}
