import Foundation
import DevHubData
import DevHubDomain
import DevHubPresentation

@MainActor
public final class AppContainer {
    let shell: ShellRunner
    let assembly: PresentationAssembly
    private var hotKey: GlobalHotKey?
    private var windows: AppWindows?

    private init(shell: ShellRunner, assembly: PresentationAssembly) {
        self.shell = shell
        self.assembly = assembly
    }

    public static func live() -> AppContainer {
        let commandLog = CommandLog()
        let shell = ShellRunner(recorder: CommandLogRecorder(log: commandLog))
        let ports = Ports.live(shell: shell)
        let useCases = UseCases(ports: ports)
        let store = UserDefaultsKeyValueStore(defaults: UserDefaults.standard)
        let savedProjects = store.decode([Project].self, forKey: PreferenceKeys.projects)
        let assembly = PresentationAssembly(
            ports: ports,
            useCases: useCases,
            store: store,
            commandLog: commandLog,
            projects: savedProjects ?? [],
            selectedProjectID: store.string(forKey: PreferenceKeys.selectedProject),
            settings: store.decode(AppSettings.self, forKey: PreferenceKeys.settings) ?? AppSettings(),
            recentEvents: []
        )
        let container = AppContainer(shell: shell, assembly: assembly)
        container.startSystemIntegration()
        return container
    }

    private func startSystemIntegration() {
        let windows = AppWindows(assembly: assembly)
        self.windows = windows
        let hotKey = GlobalHotKey { windows.showPinnedOrPanel() }
        self.hotKey = hotKey
        let settings = assembly.settings
        settings.onShortcutChange = { hotKey.register($0) }
        DispatchQueue.main.async { [settings, assembly] in
            windows.start()
            hotKey.register(settings.values.globalShortcut)
            if settings.values.showDockIcon {
                settings.applyDockIcon()
            }
            #if DEBUG
            DebugLaunch.apply(assembly: assembly, windows: windows)
            #endif
        }
    }
}
