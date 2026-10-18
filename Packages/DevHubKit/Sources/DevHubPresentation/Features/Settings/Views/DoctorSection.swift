import SwiftUI
import DevHubDomain
import DevHubUI

struct DoctorSection: View {
    @Environment(DoctorStore.self) private var doctor
    @Environment(Notifier.self) private var notifier

    var body: some View {
        Section {
            ForEach(doctor.statuses, id: \.tool.name) { status in
                DoctorRow(model: DoctorRowMapper.model(for: status)) {}
            }
            DoctorRow(model: DoctorRowMapper.accessibility(isTrusted: doctor.isAccessibilityTrusted)) {
                if doctor.isAccessibilityTrusted == false {
                    Button("Open System Settings") {
                        doctor.requestAccessibility()
                    }
                    .controlSize(.small)
                    .fixedSize()
                }
            }
            DoctorRow(model: DoctorRowMapper.notifications(notifier.permission)) {}
        } header: {
            HStack {
                Text("Doctor")
                Spacer()
                if doctor.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("Check Again") {
                    Task { await doctor.check() }
                }
                .controlSize(.small)
                .disabled(doctor.isChecking)
            }
        } footer: {
            Text("DevHub looks for each tool in /opt/homebrew/bin, /usr/local/bin, ~/.local/bin and its own PATH. A tool that a project does not use can stay missing.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .task {
            await doctor.check()
            await notifier.refreshPermission()
        }
    }
}

#Preview {
    Form {
        DoctorSection()
    }
    .formStyle(.grouped)
    .previewEnvironment()
}
