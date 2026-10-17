import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct ContainerLocatorTests {
    private let tree: SimulatorContainerTree

    init() throws {
        tree = SimulatorContainerTree(directory: try TemporaryDirectory())
    }

    @Test func findsTheDataContainerByBundleID() throws {
        _ = try tree.makeDataContainer(folder: "OTHER", bundleID: "com.example.other")
        let expected = try tree.makeDataContainer(folder: "APP", bundleID: SimulatorContainerTree.bundleID)

        let found = ContainerLocator.find(udid: SimulatorContainerTree.udid, bundleID: SimulatorContainerTree.bundleID, kind: "data", devicesRoot: tree.devicesRoot)

        #expect(found.map { URL(fileURLWithPath: $0).standardizedFileURL } == URL(fileURLWithPath: expected).standardizedFileURL)
    }

    @Test func anUnknownAppHasNoContainer() {
        #expect(ContainerLocator.find(udid: SimulatorContainerTree.udid, bundleID: "com.example.none", kind: "data", devicesRoot: tree.devicesRoot) == nil)
    }
}
