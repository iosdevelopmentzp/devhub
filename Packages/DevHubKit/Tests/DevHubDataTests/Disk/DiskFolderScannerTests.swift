import DevHubDomain
import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct DiskFolderScannerTests {
    private let home: TemporaryDirectory

    init() throws {
        home = try TemporaryDirectory()
    }

    private var derivedDataRoot: URL {
        home.url.appendingPathComponent("Library/Developer/Xcode/DerivedData")
    }

    private func derivedData(_ folder: String, workspace: String) throws {
        let plist = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0"><dict><key>WorkspacePath</key><string>\(workspace)</string></dict></plist>
        """
        _ = try home.write(plist, to: "Library/Developer/Xcode/DerivedData/\(folder)/info.plist")
    }

    @Test func derivedDataOfAnExistingProjectIsOneItemEachAndTheRestIsStale() throws {
        _ = try home.write("", to: "Developer/example-app/ExampleApp.xcworkspace")
        try derivedData("ExampleApp-abc", workspace: home.path("Developer/example-app/ExampleApp.xcworkspace"))
        try derivedData("OldApp-def", workspace: home.path("Developer/old-app/OldApp.xcodeproj"))
        try derivedData("GoneApp-ghi", workspace: home.path("Developer/gone-app/GoneApp.xcodeproj"))
        _ = try home.write("", to: "Library/Developer/Xcode/DerivedData/ModuleCache.noindex/x")

        let items = DiskFolderScanner.derivedData(root: derivedDataRoot)

        #expect(items.map(\.kind) == [.staleDerivedData, .derivedData])
        #expect(items[0].count == 2)
        #expect(items[0].paths.map { ($0 as NSString).lastPathComponent } == ["GoneApp-ghi", "OldApp-def"])
        #expect(items[1].id.hasPrefix("derivedData:/"))
        #expect(items[1].id.hasSuffix("/Library/Developer/Xcode/DerivedData/ExampleApp-abc"))
        #expect(items[1].name == "ExampleApp.xcworkspace")
        #expect(items[1].detail == home.path("Developer/example-app/ExampleApp.xcworkspace"))
    }

    @Test func archivesDeviceSupportAndCachesAreFound() throws {
        _ = try home.write("", to: "Library/Developer/Xcode/Archives/2026-10-01/ExampleApp.xcarchive/Info.plist")
        _ = try home.write("", to: "Library/Developer/Xcode/Archives/2026-10-02/ExampleApp.xcarchive/Info.plist")
        _ = try home.write("", to: "Library/Developer/Xcode/iOS DeviceSupport/18.6 (22G86)/Symbols/x")
        _ = try home.write("", to: "Library/Developer/Xcode/watchOS DeviceSupport/11.0 (22R100)/Symbols/x")
        _ = try home.write("", to: "Library/Caches/org.swift.swiftpm/repositories/x")

        let items = DiskFolderScanner.items(home: home.url, derivedDataRoot: derivedDataRoot)

        #expect(items.map(\.kind) == [.archives, .deviceSupport, .swiftPMCache])
        #expect(items[0].count == 2)
        #expect(items[1].count == 2)
        #expect(items[1].paths.allSatisfy { $0.contains(" DeviceSupport/") })
        #expect(items[2].paths == [home.path("Library/Caches/org.swift.swiftpm")])
    }

    @Test func anEmptyHomeHasNothingToClean() {
        #expect(DiskFolderScanner.items(home: home.url, derivedDataRoot: derivedDataRoot).isEmpty)
    }
}
