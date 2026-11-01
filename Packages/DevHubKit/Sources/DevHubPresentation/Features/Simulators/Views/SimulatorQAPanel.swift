import SwiftUI
import DevHubDomain
import DevHubUI

struct SimulatorQAPanel: View {
    @Environment(SimulatorQAStore.self) private var qa
    @Environment(MediaStore.self) private var media
    @Environment(AppActions.self) private var appActions

    let simulator: Simulator
    let bundleID: String
    let onClose: () -> Void

    @State private var service = PrivacyService.photos

    private var isBooted: Bool {
        simulator.state == .booted
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            OperationSlot(origin: .simulator(simulator.id))
            line("Appearance") {
                Button("Light", systemImage: "sun.max") { apply(.appearance(.light)) }
                Button("Dark", systemImage: "moon") { apply(.appearance(.dark)) }
            }
            line("Text size") {
                Menu("Choose…") {
                    ForEach(SimulatorTextSize.allCases, id: \.self) { size in
                        Button(SimulatorQAText.title(for: size)) { apply(.textSize(size)) }
                    }
                }
                .fixedSize()
            }
            line("Status bar") {
                Button("Clean 9:41", systemImage: "wand.and.stars") { apply(.cleanStatusBar) }
                    .hint("Full battery, full signal, Wi-Fi and 9:41, for screenshots")
                Button("Real", systemImage: "arrow.uturn.backward") { apply(.resetStatusBar) }
            }
            line("Location") {
                Menu("Set…") {
                    ForEach(SimulatorQAText.locations, id: \.title) { location in
                        Button(location.title) { apply(.location(latitude: location.latitude, longitude: location.longitude)) }
                    }
                }
                .fixedSize()
                Button("Clear") { apply(.clearLocation) }
            }
            line("Language") {
                Menu("Set…") {
                    ForEach(SimulatorQAText.languages, id: \.code) { language in
                        Button(language.title) { apply(.language(code: language.code, locale: language.locale)) }
                    }
                }
                .fixedSize()
                if qa.needsReboot.contains(simulator.id) {
                    Text("Shut down and boot the simulator to see it")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
            line("Permission") {
                Picker("Service", selection: $service) {
                    ForEach(PrivacyService.allCases, id: \.self) { service in
                        Text(SimulatorQAText.title(for: service)).tag(service)
                    }
                }
                .labelsHidden()
                .fixedSize()
                ForEach(PrivacyChange.allCases, id: \.self) { change in
                    Button(change.rawValue.capitalized) { apply(.privacy(change, service: service, bundleID: bundleID)) }
                }
                .disabled(bundleID.isEmpty)
            }
            line("Screenshot") {
                Button("Save to Desktop", systemImage: "camera") { qa.screenshot(simulator) }
                Toggle("With frame", isOn: Binding(get: { qa.framesScreenshots }, set: { qa.framesScreenshots = $0 }))
                    .toggleStyle(.checkbox)
                    .fixedSize()
                    .hint("Draws the device frame of Xcode around the screenshot")
                if let path = qa.screenshots[simulator.id] {
                    Button((path as NSString).lastPathComponent) { appActions.openInFinder(path: path) }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hint("Show in Finder")
                }
            }
            line("Video") {
                if qa.isRecording(simulator.id) {
                    Button("Stop", systemImage: "stop.circle") { qa.stopRecording(simulator.id) }
                    if let start = qa.recordingStarts[simulator.id] {
                        Text(start, style: .timer)
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.red)
                    } else {
                        Text("Starting…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    Button("Record", systemImage: "record.circle") { qa.startRecording(simulator) }
                }
                if let path = qa.recordings[simulator.id] {
                    Button((path as NSString).lastPathComponent) { appActions.openInFinder(path: path) }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hint("Show in Finder")
                }
                Menu("Convert", systemImage: "film.stack") {
                    if let path = qa.recordings[simulator.id] {
                        Section("Last recording") {
                            ForEach(MediaChoice.allCases) { choice in
                                Button(choice.title) { media.convert(path, to: choice, at: .simulator(simulator.id)) }
                            }
                        }
                    }
                    Section("Choose a video file") {
                        ForEach(MediaChoice.allCases) { choice in
                            Button(choice.title + "…") { convertFile(to: choice) }
                        }
                    }
                }
                .fixedSize()
                .hint("Make a GIF or a smaller MP4")
                if let output = media.outputs[.simulator(simulator.id)] {
                    Button((output as NSString).lastPathComponent) { appActions.openInFinder(path: output) }
                        .buttonStyle(LinkButtonStyle(.accent))
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .hint("Show in Finder")
                }
            }
            HStack {
                Text(isBooted ? "For \(bundleID.isEmpty ? "the simulator" : bundleID)" : "Boot the simulator first")
                    .font(.caption)
                    .foregroundStyle(isBooted ? Color.secondary : .orange)
                Spacer()
                if qa.isBusy(simulator.id) {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Close", action: onClose)
                    .controlSize(.small)
            }
        }
        .controlSize(.small)
        .disabled(isBooted == false)
        .padding(10)
        .background(Theme.base, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .onChange(of: simulator.state) { _, state in
            guard state == .shutdown else { return }
            qa.rebooted(simulator.id)
        }
    }

    private func apply(_ setting: SimulatorSetting) {
        qa.apply(setting, to: simulator)
    }


    private func convertFile(to choice: MediaChoice) {
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        guard let url = FolderPicker.chooseFile(directory: desktop, prompt: "Convert", message: "Choose a .mov, .mp4 or .m4v video") else { return }
        media.convert(url.path, to: choice, at: .simulator(simulator.id))
    }

    private func line<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .frame(width: 80, alignment: .leading)
            FlowLayout(spacing: 6) {
                content()
            }
        }
    }
}

#Preview {
    SimulatorQAPanel(simulator: Simulator(id: "preview", name: "iPhone 17", kind: .phone, state: .booted, isFavorite: false), bundleID: "com.example.app", onClose: {})
        .previewEnvironment()
        .padding()
        .frame(width: 640)
}
