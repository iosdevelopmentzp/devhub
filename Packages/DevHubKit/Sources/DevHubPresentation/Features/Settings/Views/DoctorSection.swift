import SwiftUI
import DevHubDomain
import DevHubUI

struct DoctorSection: View {
    @Environment(DoctorStore.self) private var doctor
    @Environment(Notifier.self) private var notifier
    @Environment(CIDiagnosticsStore.self) private var ciDiagnostics
    @Environment(CIBranchRunsStore.self) private var ciRuns
    @Environment(SupportBundleStore.self) private var supportBundle

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
            LabeledContent {
                HStack(spacing: 8) {
                    Button("Copy") {
                        Task { await supportBundle.copy() }
                    }
                    Button("Save…") {
                        Task { await supportBundle.save() }
                    }
                }
                .controlSize(.small)
                .fixedSize()
                .disabled(supportBundle.isBusy)
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Support bundle")
                    Text("One text for a bug report: the version, settings, tools, config problems, the last 100 commands, Recent and the last crash of DevHub. Links, e-mails, IP addresses, tokens, your user name, paths, project, scheme and bundle names, branches and logins are replaced.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        } header: {
            HStack {
                Text("Doctor")
                Spacer()
                if doctor.isChecking {
                    ProgressView()
                        .controlSize(.small)
                }
                Button("CI Diagnostics…") {
                    Task { await ciDiagnostics.save(CIDiagnosticsSnapshot(branchRun: ciRuns.run, branchWorkflows: ciRuns.workflows, baseRun: ciRuns.baseRun, baseWorkflows: ciRuns.baseWorkflows)) }
                }
                .controlSize(.small)
                .disabled(ciDiagnostics.isBusy)
                .hint(PullRequestDetailsMapper.ciDiagnosticsHint)
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
