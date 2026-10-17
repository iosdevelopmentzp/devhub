import DevHubDomain
import DevHubUI
import Testing
@testable import DevHubPresentation

@Suite struct SimulatorRowMapperTests {
    let noSettings = SimulatorIdentitySettings(hasApplied: false)

    @Test func configActionsPassThrough() {
        var flags = Flags()
        flags.configActions = [.preview]

        #expect(row(SimulatorFixture.iPhone, flags: flags).configActions == [.preview])
        #expect(row(SimulatorFixture.iPhone, flags: Flags()).configActions.isEmpty)
    }

    @Test func statusLineAndItsTint() {
        var flags = Flags()
        #expect(row(SimulatorFixture.iPhone, flags: flags).status == nil)

        flags.status = SimulatorStatus(text: "Environment: staging", isFailure: false)
        let plain = row(SimulatorFixture.iPhone, flags: flags)
        flags.status = SimulatorStatus(text: "status timed out", isFailure: true)
        let failed = row(SimulatorFixture.iPhone, flags: flags)

        #expect(plain.status == SimulatorStatusLineModel(text: "Environment: staging", tint: .secondary))
        #expect(failed.status == SimulatorStatusLineModel(text: "status timed out", tint: .red))
    }

    @Test func kindIcon() {
        #expect(SimulatorRowMapper.kindIcon(.phone) == "iphone")
        #expect(SimulatorRowMapper.kindIcon(.pad) == "ipad")
    }

    @Test func stateTable() {
        let table: [(Simulator.State, Tint, Double, String, String, Bool)] = [
            (.booted, .green, 1, "Booted", "Shutdown", true),
            (.booting, .orange, 1, "Booting…", "Boot", false),
            (.shuttingDown, .orange, 1, "Shutting down…", "Boot", false),
            (.shutdown, .secondary, 0.35, "Shutdown", "Boot", true)
        ]

        for (state, tint, opacity, text, powerHint, isStable) in table {
            var simulator = SimulatorFixture.iPhone
            simulator.state = state
            let model = row(simulator, flags: Flags())
            #expect(model.stateTint == tint)
            #expect(model.stateDotOpacity == opacity)
            #expect(model.stateText == text)
            #expect(model.detailText == text)
            #expect(model.powerHint == powerHint)
            #expect(model.canStreamLogs == (state == .booted))
            #expect(model.canTogglePower == isStable)
            #expect(model.canErase == isStable)
            #expect(model.canRemoveApps == isStable)
            #expect(model.canUninstallFromMenu == isStable)
        }
    }

    @Test func plainRow() {
        let model = row(SimulatorFixture.iPhone, flags: Flags())

        #expect(model.id == SimulatorFixture.iPhone.id)
        #expect(model.name == "iPhone 16 Pro")
        #expect(model.runtimeTag == TagModel("iOS 18.2"))
        #expect(model.kindIcon == "iphone")
        #expect(model.isHighlighted == false)
        #expect(model.targetTag == nil)
        #expect(model.isFavorite == false)
        #expect(model.favoriteIcon == "star.fill")
        #expect(model.favoriteHint == "In favorites")
        #expect(model.favoriteMenuTitle == "Add to Favorites")
        #expect(model.identity == nil)
        #expect(model.hasIdentityConfig == false)
        #expect(model.isUninstalling == false)
        #expect(model.canBuildAndRun)
        #expect(model.canLaunchAndAttach == false)
        #expect(model.uninstallTitle == "Uninstall com.example.app")
        #expect(model.copyUDIDLabel == "UDID \(SimulatorFixture.iPhone.id)")
        #expect(model.eraseConfirmation == "Erase all content and settings on iPhone 16 Pro? The simulator shuts down first.")
        #expect(model.isConfirmingErase == false)
        #expect(model.isEditingIdentity == false)
        #expect(model.isMessaging == false)
        #expect(model.pinsActions == false)
    }

    @Test func installedAppsAreCountedInTheDetail() {
        var flags = Flags()
        flags.installedApps = 1
        #expect(row(SimulatorFixture.iPhone, flags: flags).detailText == "Booted · 1 app installed")

        flags.installedApps = 3
        #expect(row(SimulatorFixture.iPhone, flags: flags).detailText == "Booted · 3 apps installed")
    }

    @Test func uninstallingReplacesTheDetailAndPinsActions() {
        var flags = Flags()
        flags.isUninstalling = true
        flags.installedApps = 3

        let model = row(SimulatorFixture.iPhone, flags: flags)

        #expect(model.detailText == "Removing apps…")
        #expect(model.isUninstalling)
        #expect(model.canUninstallFromMenu == false)
        #expect(model.pinsActions)
    }

    @Test func targetIsHighlightedAndTagged() {
        var flags = Flags()
        flags.isTarget = true

        let model = row(SimulatorFixture.iPhone, flags: flags)

        #expect(model.isHighlighted)
        #expect(model.targetTag == TagModel("target", tint: .blue, hint: "Build & Run and the run bar above use this simulator. Click a row to change it."))
        #expect(model.pinsActions)
    }

    @Test func favoriteMenuTitle() {
        var simulator = SimulatorFixture.iPhone
        simulator.isFavorite = true

        let model = row(simulator, flags: Flags())

        #expect(model.isFavorite)
        #expect(model.favoriteMenuTitle == "Remove from Favorites")
    }

    @Test func runningBuildDisablesBuildActions() {
        var flags = Flags()
        flags.buildIsRunning = true
        flags.identity = AppIdentityFixture.installed

        let model = row(SimulatorFixture.iPhone, flags: flags)

        #expect(model.canBuildAndRun == false)
        #expect(model.canRemoveApps == false)
        #expect(model.canLaunchAndAttach == false)
        #expect(model.canTogglePower)
    }

    @Test func launchAndAttachNeedsInstalledApp() {
        var flags = Flags()
        flags.identity = AppIdentityFixture.installed
        #expect(row(SimulatorFixture.iPhone, flags: flags).canLaunchAndAttach)

        flags.identity = .notInstalled
        #expect(row(SimulatorFixture.iPhone, flags: flags).canLaunchAndAttach == false)
    }

    @Test func identitySummaryNeedsConfigAndInstalledApp() {
        var flags = Flags()
        flags.identity = AppIdentityFixture.installed
        #expect(row(SimulatorFixture.iPhone, flags: flags).identity == nil)

        flags.hasIdentityConfig = true
        flags.isApplying = true
        let model = row(SimulatorFixture.iPhone, flags: flags)
        #expect(model.hasIdentityConfig)
        #expect(model.identity == IdentityPanelMapper.summary(for: AppIdentityFixture.installed, settings: noSettings, aliases: [:], mockState: nil, isApplying: true))

        flags.identity = .notInstalled
        #expect(row(SimulatorFixture.iPhone, flags: flags).identity == nil)
    }

    @Test func editingAndMessagingPinActions() {
        var editing = Flags()
        editing.isEditingIdentity = true
        var messaging = Flags()
        messaging.isMessaging = true

        #expect(row(SimulatorFixture.iPhone, flags: editing).pinsActions)
        #expect(row(SimulatorFixture.iPhone, flags: editing).isEditingIdentity)
        #expect(row(SimulatorFixture.iPhone, flags: messaging).pinsActions)
        #expect(row(SimulatorFixture.iPhone, flags: messaging).isMessaging)
    }

    @Test func showsActionsOnHoverOrPinUnlessConfirmingErase() {
        var flags = Flags()
        let plain = row(SimulatorFixture.iPhone, flags: flags)
        flags.isTarget = true
        let pinned = row(SimulatorFixture.iPhone, flags: flags)
        flags.isConfirmingErase = true
        let confirming = row(SimulatorFixture.iPhone, flags: flags)

        #expect(plain.showsActions(isHovered: false) == false)
        #expect(plain.showsActions(isHovered: true))
        #expect(pinned.showsActions(isHovered: false))
        #expect(confirming.isConfirmingErase)
        #expect(confirming.showsActions(isHovered: true) == false)
    }

    private func row(_ simulator: Simulator, flags: Flags) -> SimulatorRowModel {
        SimulatorRowMapper.model(
            for: simulator,
            runtime: "iOS 18.2",
            isTarget: flags.isTarget,
            installedApps: flags.installedApps,
            status: flags.status,
            identity: flags.identity,
            identitySettings: noSettings,
            deviceIDAliases: [:],
            mockState: nil,
            hasIdentityConfig: flags.hasIdentityConfig,
            isUninstalling: flags.isUninstalling,
            isApplying: flags.isApplying,
            buildIsRunning: flags.buildIsRunning,
            bundleID: "com.example.app",
            isConfirmingErase: flags.isConfirmingErase,
            isEditingIdentity: flags.isEditingIdentity,
            isMessaging: flags.isMessaging,
            configActions: flags.configActions
        )
    }
}

private struct Flags {
    var configActions: [ConfigActionItemModel] = []
    var isTarget = false
    var installedApps: Int?
    var status: SimulatorStatus?
    var identity: AppIdentity?
    var hasIdentityConfig = false
    var isUninstalling = false
    var isApplying = false
    var buildIsRunning = false
    var isConfirmingErase = false
    var isEditingIdentity = false
    var isMessaging = false
}
