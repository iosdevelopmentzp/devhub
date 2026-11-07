import DevHubDomain
import Foundation
import Testing
@testable import DevHubData

@Suite struct DevicectlDeviceRepositoryTests {
    @Test func launchArgumentsTerminateTheOldProcessAndPassTheEnvironmentAsJSON() {
        let arguments = DevicectlDeviceRepository.launchArguments(
            udid: "00008110-000000000000001B",
            bundleID: "com.example.app",
            environment: ["B": "2", "A": "1"],
            arguments: ["-skipOnboarding", "YES"],
            startStopped: false
        )

        #expect(arguments == [
            "device", "process", "launch", "--device", "00008110-000000000000001B", "--terminate-existing",
            "--environment-variables", "{\"A\":\"1\",\"B\":\"2\"}",
            "com.example.app", "-skipOnboarding", "YES",
        ])
    }

    @Test func launchArgumentsWithoutAnEnvironmentSkipTheFlag() {
        let arguments = DevicectlDeviceRepository.launchArguments(udid: "D1", bundleID: "com.example.app", environment: [:], arguments: [], startStopped: false)

        #expect(arguments == ["device", "process", "launch", "--device", "D1", "--terminate-existing", "com.example.app"])
    }

    @Test func aStoppedLaunchWaitsForTheDebugger() {
        let arguments = DevicectlDeviceRepository.launchArguments(udid: "D1", bundleID: "com.example.app", environment: [:], arguments: [], startStopped: true)

        #expect(arguments == ["device", "process", "launch", "--device", "D1", "--terminate-existing", "--start-stopped", "com.example.app"])
    }

    @Test func copyArgumentsNameTheAppDataContainer() {
        let from = DevicectlDeviceRepository.copyArguments(udid: "D1", bundleID: "com.example.app", from: "Library/Preferences/group.com.example.app.plist", to: "/tmp/x.plist")
        let to = DevicectlDeviceRepository.copyArguments(udid: "D1", bundleID: "com.example.app", from: "/tmp/x.plist", to: "Library/Preferences/group.com.example.app.plist", direction: "to")

        #expect(from == [
            "device", "copy", "from", "--device", "D1",
            "--domain-type", "appDataContainer", "--domain-identifier", "com.example.app",
            "--source", "Library/Preferences/group.com.example.app.plist", "--destination", "/tmp/x.plist",
        ])
        #expect(to.prefix(3) == ["device", "copy", "to"])
        #expect(to.suffix(2) == ["--destination", "Library/Preferences/group.com.example.app.plist"])
    }
}
