import Foundation
import DevHubDomain

extension MockData {
    package static let installedApps: [Simulator.ID: InstalledApp] = [
        "sim-17pro": InstalledApp(isInstalled: true, version: "1.5.2", hasIdentityHook: true, keepsIdentity: false, storedProfileID: "staging")
    ]

    package static let appReports: [Simulator.ID: AppStateReport] = [
        "sim-17pro": AppStateReport(identity: "devhub-3f9a1c2e", profile: "staging", host: "api.staging.example.com", user: "qa-12", version: "1.5.2", tags: [ScriptViewTag(text: "beta", tint: .purple, icon: "flask", hint: "Beta features are on")])
    ]
}
