import Foundation
import DevHubDomain

struct MockAppLaunchRepository: AppLaunchRepository {

    func inspect(udid: String, bundleID: String, identity: LaunchIdentityConfig?, storage: ProfileStorage?) async -> InstalledApp {
        MockData.installedApps[udid] ?? .notInstalled
    }

    func cleanInstall(udid: String, bundleID: String, fallbackAppPath: String?) async throws {
        try await Task.sleep(for: .milliseconds(800))
    }

    func containers(udid: String, bundleID: String) async -> AppContainers {
        AppContainers(
            app: "/tmp/Containers/Bundle/\(bundleID).app",
            data: "/tmp/Containers/Data/\(bundleID)",
            groups: [AppDataFile(name: "group.\(bundleID)", path: "/tmp/Containers/Shared/group.\(bundleID)", size: 0)]
        )
    }
}
