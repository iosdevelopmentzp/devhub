import DevHubDomain
import Foundation
import Testing
@testable import DevHubPresentation

@Suite struct DiskCleanupMapperTests {
    private let items = [
        DiskCleanupItem(id: "runtime:a", kind: .simulatorRuntime, name: "iOS 26.4", detail: "23E244", size: 8_000_000_000, lastUsed: .now, runtimeID: "a"),
        DiskCleanupItem(id: "cocoaPodsCache", kind: .cocoaPodsCache, paths: ["/Users/alex/Library/Caches/CocoaPods"]),
        DiskCleanupItem(id: "derivedData:small", kind: .derivedData, name: "ExampleWidget.xcodeproj", detail: "/Users/alex/Developer/example-widget/ExampleWidget.xcodeproj", paths: ["/dd/small"]),
        DiskCleanupItem(id: "staleDerivedData", kind: .staleDerivedData, paths: ["/dd/a", "/dd/b"], count: 2),
        DiskCleanupItem(id: "derivedData:large", kind: .derivedData, name: "ExampleApp.xcworkspace", detail: "/Users/alex/Developer/example-app/ExampleApp.xcworkspace", paths: ["/dd/large"]),
    ]

    @Test func singleLinesComeInAFixedOrderAndGroupsAfterThem() {
        let model = DiskCleanupMapper.model(items: items, sizes: [:], measuringIDs: [], busyIDs: [])

        #expect(model.rows.map(\.id) == ["staleDerivedData", "cocoaPodsCache"])
        #expect(model.groups.map(\.id) == [.derivedData, .simulatorRuntime])
        #expect(model.groups[0].title == "DerivedData by project")
        #expect(model.groups[1].rows.map(\.title) == ["iOS 26.4"])
        #expect(model.isEmpty == false)
    }

    @Test func projectsAreSortedByMeasuredSize() {
        let model = DiskCleanupMapper.model(items: items, sizes: ["derivedData:large": 900, "derivedData:small": 100], measuringIDs: [], busyIDs: [])

        #expect(model.groups[0].rows.map(\.title) == ["ExampleApp.xcworkspace", "ExampleWidget.xcodeproj"])
        #expect(model.groups[0].summary.hasPrefix("2 projects · "))
        #expect(model.totalText != nil)
    }

    @Test func aStaleLineCountsItsFoldersAndWarnsThatItIsFinal() {
        let row = DiskCleanupMapper.row(for: items[3], size: 2048, isMeasuring: false, isBusy: false)

        #expect(row.title == "DerivedData of deleted projects")
        #expect(row.detail == "2 folders whose project is gone")
        #expect(row.icon == "hammer.circle")
        #expect(row.sizeText != nil)
        #expect(row.confirmTitle.hasPrefix("Delete DerivedData of deleted projects ("))
        #expect(row.warnings == ["This cannot be undone. Nothing goes to the Trash."])
        #expect(row.deleteHint.hasSuffix("rm -rf 2 folders"))
    }

    @Test func aRuntimeLineNamesTheCommandAndTheBuild() {
        let row = DiskCleanupMapper.row(for: items[0], size: items[0].size, isMeasuring: false, isBusy: false)

        #expect(row.detail.hasPrefix("build 23E244 · used "))
        #expect(row.deleteHint.hasSuffix("xcrun simctl runtime delete a"))
        #expect(row.confirmTitle.hasPrefix("Delete the iOS 26.4 simulator runtime ("))
        #expect(row.warnings.count == 2)
    }

    @Test func aBusyLineCannotBeDeletedAgain() {
        let row = DiskCleanupMapper.row(for: items[1], size: nil, isMeasuring: true, isBusy: true)

        #expect(row.canDelete == false)
        #expect(row.isMeasuring)
        #expect(row.sizeText == nil)
        #expect(row.confirmTitle == "Delete CocoaPods cache?")
    }

    @Test func nothingFoundIsEmpty() {
        let model = DiskCleanupMapper.model(items: [], sizes: [:], measuringIDs: [], busyIDs: [])

        #expect(model.isEmpty)
        #expect(model.totalText == nil)
    }
}
