import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct ProfileDefaultsPlanTests {
    @Test func anAppGroupOfTheAppUsesTheGroupContainer() {
        let groups = ["group.com.example.app", "group.com.example.app.widgets"]

        #expect(ProfileDefaultsPlan.containerKind(suite: "group.com.example.app", appGroups: groups) == "group.com.example.app")
        #expect(ProfileDefaultsPlan.containerKind(suite: "com.example.app", appGroups: groups) == "data")
    }

    @Test func aGroupSuiteWithoutThatAppGroupUsesTheDataContainer() {
        #expect(ProfileDefaultsPlan.containerKind(suite: "group.com.example.app", appGroups: []) == "data")
        #expect(ProfileDefaultsPlan.containerKind(suite: "group.com.example.app", appGroups: ["group.com.example.app.widgets"]) == "data")
    }

    @Test func onlyAGroupSuiteNeedsTheAppGroupsOfTheApp() {
        #expect(ProfileDefaultsPlan.mayUseAppGroup(["com.example.app", "group.com.example.app"]))
        #expect(ProfileDefaultsPlan.mayUseAppGroup(["com.example.app"]) == false)
        #expect(ProfileDefaultsPlan.mayUseAppGroup([]) == false)
    }

    @Test func theTypeChoosesTheDefaultsFlag() {
        let folder = "/data/Library/Preferences"

        #expect(ProfileDefaultsPlan.writeArguments(ProfileDefault(suite: "s", key: "k", value: "x"), udid: "U", folder: folder) == ["spawn", "U", "defaults", "write", "/data/Library/Preferences/s.plist", "k", "-string", "x"])
        #expect(ProfileDefaultsPlan.writeArguments(ProfileDefault(suite: "s", key: "k", value: "YES", type: "bool"), udid: "U", folder: folder).suffix(2) == ["-bool", "true"])
        #expect(ProfileDefaultsPlan.writeArguments(ProfileDefault(suite: "s", key: "k", value: "3", type: "int"), udid: "U", folder: folder).suffix(2) == ["-integer", "3"])
    }

    @Test func localWriteArgumentsTargetAPlistInTheFolderWithoutTheExtension() {
        let item = ProfileDefault(suite: "group.com.example.app", key: "environment", value: "staging")

        #expect(ProfileDefaultsPlan.localWriteArguments(item, folder: "/tmp/prefs") == ["write", "/tmp/prefs/group.com.example.app", "environment", "-string", "staging"])
        #expect(ProfileDefaultsPlan.preferencesPath(suite: "group.com.example.app") == "Library/Preferences/group.com.example.app.plist")
    }
}
