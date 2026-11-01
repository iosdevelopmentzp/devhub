import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct SimctlAppDataRepositoryTests {
    @Test func thePlistOfASuiteLivesInLibraryPreferences() {
        #expect(SimctlAppDataRepository.plistPath(name: "group.com.example.app", root: "/group") == "/group/Library/Preferences/group.com.example.app.plist")
    }

    @Test func writeArgumentsPassTheTypeOfTheValue() {
        let plist = "/data/Library/Preferences/com.example.app.plist"
        let prefix = ["spawn", "U1", "defaults", "write", plist]

        #expect(SimctlAppDataRepository.writeArguments(.string("staging"), key: "env", plistPath: plist, udid: "U1") == prefix + ["env", "-string", "staging"])
        #expect(SimctlAppDataRepository.writeArguments(.integer(3), key: "count", plistPath: plist, udid: "U1") == prefix + ["count", "-integer", "3"])
        #expect(SimctlAppDataRepository.writeArguments(.float(0.5), key: "volume", plistPath: plist, udid: "U1") == prefix + ["volume", "-float", "0.5"])
        #expect(SimctlAppDataRepository.writeArguments(.bool(false), key: "done", plistPath: plist, udid: "U1") == prefix + ["done", "-bool", "false"])
    }
}
