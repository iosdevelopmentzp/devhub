import Testing
@testable import DevHubDomain

@Suite struct CleanInstallPolicyTests {
    private let realID = "6F9619FF-8B86-D011-B42D-00C04FC964FF"
    private let notApplied = SimulatorIdentitySettings(hasApplied: false)

    @Test func noIdentityNeedsNoCleanInstall() {
        #expect(needs(identity: nil, settings: notApplied, desired: "X") == false)
    }

    @Test func appNotInstalledNeedsNoCleanInstall() {
        #expect(needs(identity: .notInstalled, settings: notApplied, desired: "X") == false)
    }

    @Test func desiredIDEqualToTheLastIDNeedsNoCleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: "A"), settings: notApplied, desired: "A") == false)
    }

    @Test func desiredIDDifferentFromTheLastIDNeedsACleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: "A"), settings: notApplied, desired: "B"))
    }

    @Test func desiredIDMatchesTheAppliedIDWhenTheAppReportsNone() {
        let settings = SimulatorIdentitySettings(appliedDeviceID: "A", hasApplied: true)

        #expect(needs(identity: installed(lastDeviceID: nil), settings: settings, desired: "A") == false)
    }

    @Test func desiredIDWithNoKnownIDNeedsACleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: nil), settings: notApplied, desired: "A"))
    }

    @Test func appliedIDIsIgnoredWhenNotApplied() {
        let settings = SimulatorIdentitySettings(appliedDeviceID: "A", hasApplied: false)

        #expect(needs(identity: installed(lastDeviceID: nil), settings: settings, desired: "A"))
    }

    @Test func noDesiredAndNoKnownIDNeedsNoCleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: nil), settings: notApplied, desired: nil) == false)
    }

    @Test func noDesiredAndARealDeviceIDNeedsNoCleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: realID), settings: notApplied, desired: nil) == false)
    }

    @Test func noDesiredAndAnOverrideIDNeedsACleanInstall() {
        #expect(needs(identity: installed(lastDeviceID: "qa-device"), settings: notApplied, desired: nil))
    }

    @Test func noDesiredAndASavedIDNeedsACleanInstall() {
        let result = CleanInstallPolicy.needsCleanInstall(
            identity: installed(lastDeviceID: realID),
            settings: notApplied,
            desiredDeviceID: nil,
            savedDeviceIDs: [realID]
        )

        #expect(result)
    }

    @Test func noDesiredAndAnAppliedOverrideNeedsACleanInstall() {
        let settings = SimulatorIdentitySettings(appliedDeviceID: realID, hasApplied: true)

        #expect(needs(identity: installed(lastDeviceID: realID), settings: settings, desired: nil))
    }

    @Test func savedIDIsAnOverride() {
        #expect(CleanInstallPolicy.isOverrideID(realID, savedDeviceIDs: [realID]))
    }

    @Test func nonUUIDIsAnOverride() {
        #expect(CleanInstallPolicy.isOverrideID("qa-device", savedDeviceIDs: []))
    }

    @Test func unsavedUUIDIsNotAnOverride() {
        #expect(CleanInstallPolicy.isOverrideID(realID, savedDeviceIDs: ["other"]) == false)
    }

    private func installed(lastDeviceID: String?) -> AppIdentity {
        AppIdentity(isInstalled: true, version: "1.0", hasDebugHooks: true, lastDeviceID: lastDeviceID)
    }

    private func needs(identity: AppIdentity?, settings: SimulatorIdentitySettings, desired: String?) -> Bool {
        CleanInstallPolicy.needsCleanInstall(identity: identity, settings: settings, desiredDeviceID: desired, savedDeviceIDs: [])
    }
}
