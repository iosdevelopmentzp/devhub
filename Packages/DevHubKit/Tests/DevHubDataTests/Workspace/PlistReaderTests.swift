import DevHubTestSupport
import Foundation
import Testing
@testable import DevHubData

@Suite struct PlistReaderTests {
    private let directory: TemporaryDirectory

    init() throws {
        directory = try TemporaryDirectory()
    }

    @Test(arguments: [PropertyListSerialization.PropertyListFormat.xml, .binary])
    func readsDictionary(format: PropertyListSerialization.PropertyListFormat) throws {
        let url = directory.url.appendingPathComponent("Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: ["CFBundleIdentifier": "com.example.app", "Count": 3], format: format, options: 0)
        try data.write(to: url)

        let dictionary = try #require(PlistReader.dictionary(at: url))

        #expect(dictionary["CFBundleIdentifier"] as? String == "com.example.app")
        #expect(dictionary["Count"] as? Int == 3)
    }

    @Test func missingFileIsNil() {
        #expect(PlistReader.dictionary(at: directory.url.appendingPathComponent("Missing.plist")) == nil)
    }

    @Test func arrayPlistIsNil() throws {
        let url = directory.url.appendingPathComponent("Array.plist")
        try PropertyListSerialization.data(fromPropertyList: ["a", "b"], format: .xml, options: 0).write(to: url)

        #expect(PlistReader.dictionary(at: url) == nil)
    }

    @Test func textFileIsNil() throws {
        let url = try directory.write("{ not a plist", to: "Broken.plist")

        #expect(PlistReader.dictionary(at: url) == nil)
    }
}
