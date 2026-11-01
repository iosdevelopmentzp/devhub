import Foundation

package enum DiskCleanupKind: String, Hashable, Sendable, CaseIterable {
    case staleDerivedData
    case derivedData
    case unavailableSimulators
    case simulatorRuntime
    case archives
    case deviceSupport
    case swiftPMCache
    case cocoaPodsCache
}
