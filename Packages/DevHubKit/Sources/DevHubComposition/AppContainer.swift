import AppKit
import Foundation
import DevHubData
import DevHubDomain
import DevHubPresentation

@MainActor
public final class AppContainer: NSObject, NSApplicationDelegate {
    let shell: ShellRunner
    let assembly: PresentationAssembly
    private var hotKey: GlobalHotKey?
    private var windows: AppWindows?

    override public init() {
        let commandLog = CommandLog()
        let shell = ShellRunner(recorder: CommandLogRecorder(log: commandLog))
        self.shell = shell
        assembly = Self.assembly(shell: shell, commandLog: commandLog)
        super.init()
    }

    private static func assembly(shell: ShellRunner, commandLog: CommandLog) -> PresentationAssembly {
        #if DEBUG
        if ProcessInfo.processInfo.environment["DEVHUB_PORTS"] == "mock" {
            return PresentationAssembly.preview()
        }
        #endif
        let ports = Ports.live(shell: shell)
        let store = UserDefaultsKeyValueStore(defaults: UserDefaults.standard)
        return PresentationAssembly(
            ports: ports,
            useCases: UseCases(ports: ports),
            store: store,
            commandLog: commandLog,
            projects: store.decode([Project].self, forKey: PreferenceKeys.projects) ?? [],
            selectedProjectID: store.string(forKey: PreferenceKeys.selectedProject),
            settings: store.decode(AppSettings.self, forKey: PreferenceKeys.settings) ?? AppSettings(),
            recentEvents: store.decode([ActivityEvent].self, forKey: PreferenceKeys.recentEvents) ?? []
        )
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let windows = AppWindows(assembly: assembly)
        self.windows = windows
        let hotKey = GlobalHotKey { windows.toggle() }
        self.hotKey = hotKey
        let settings = assembly.settings
        settings.onShortcutChange = { hotKey.register($0) }
        windows.start()
        hotKey.register(settings.values.globalShortcut)
        #if DEBUG
        DebugLaunch.apply(assembly: assembly, windows: windows)
        #endif
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        windows?.show()
        return false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        assembly.prepareForQuit()
    }
}
