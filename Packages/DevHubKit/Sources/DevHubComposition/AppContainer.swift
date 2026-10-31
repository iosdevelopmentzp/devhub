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
        let ports = Ports.live(shell: shell)
        let useCases = UseCases(ports: ports)
        let store = UserDefaultsKeyValueStore(defaults: UserDefaults.standard)
        let savedProjects = store.decode([Project].self, forKey: PreferenceKeys.projects)
        self.shell = shell
        assembly = PresentationAssembly(
            ports: ports,
            useCases: useCases,
            store: store,
            commandLog: commandLog,
            projects: savedProjects ?? [],
            selectedProjectID: store.string(forKey: PreferenceKeys.selectedProject),
            settings: store.decode(AppSettings.self, forKey: PreferenceKeys.settings) ?? AppSettings(),
            recentEvents: store.decode([ActivityEvent].self, forKey: PreferenceKeys.recentEvents) ?? []
        )
        super.init()
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
}
