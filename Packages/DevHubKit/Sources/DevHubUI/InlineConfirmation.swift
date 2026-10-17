import SwiftUI

package struct InlineConfirmation<Details: View, Extra: View>: View {
    package enum Layout {
        case line
        case stacked(warnings: [String])
    }

    private let title: String
    private let confirmTitle: String
    private let confirmRole: ButtonRole?
    private let layout: Layout
    private let systemImage: String?
    private let tint: Color
    private let titleFont: Font
    private let onCancel: () -> Void
    private let onConfirm: () -> Void
    private let details: Details
    private let extra: Extra

    package init(
        _ title: String,
        confirmTitle: String,
        confirmRole: ButtonRole?,
        layout: Layout = .line,
        systemImage: String? = "exclamationmark.triangle.fill",
        tint: Color = .red,
        titleFont: Font = .caption,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        @ViewBuilder details: () -> Details,
        @ViewBuilder extra: () -> Extra
    ) {
        self.title = title
        self.confirmTitle = confirmTitle
        self.confirmRole = confirmRole
        self.layout = layout
        self.systemImage = systemImage
        self.tint = tint
        self.titleFont = titleFont
        self.onCancel = onCancel
        self.onConfirm = onConfirm
        self.details = details()
        self.extra = extra()
    }

    package var body: some View {
        content
            .controlSize(.small)
            .padding(8)
            .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    @ViewBuilder
    private var content: some View {
        switch layout {
        case .line:
            line
        case .stacked(let warnings):
            stacked(warnings: warnings)
        }
    }

    private var line: some View {
        HStack(spacing: 8) {
            icon
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(titleFont)
                    .fixedSize(horizontal: false, vertical: true)
                details
            }
            Spacer()
            extra
            buttons
        }
    }

    private func stacked(warnings: [String]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                icon
                Text(title)
                    .font(.caption.weight(.semibold))
            }
            ForEach(warnings, id: \.self) { warning in
                Text("• \(warning)")
                    .font(.caption)
                    .foregroundStyle(tint)
            }
            details
            HStack(spacing: 14) {
                extra
                Spacer()
                buttons
            }
            .toggleStyle(.checkbox)
            .font(.caption)
        }
    }

    @ViewBuilder
    private var icon: some View {
        if let systemImage {
            Image(systemName: systemImage)
                .foregroundStyle(tint)
        }
    }

    @ViewBuilder
    private var buttons: some View {
        Button("Cancel", action: onCancel)
        Button(confirmTitle, role: confirmRole, action: onConfirm)
            .buttonStyle(.borderedProminent)
            .tint(tint)
    }
}

package extension InlineConfirmation where Details == EmptyView {

    init(
        _ title: String,
        confirmTitle: String,
        confirmRole: ButtonRole?,
        layout: Layout = .line,
        systemImage: String? = "exclamationmark.triangle.fill",
        tint: Color = .red,
        titleFont: Font = .caption,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void,
        @ViewBuilder extra: () -> Extra
    ) {
        self.init(
            title,
            confirmTitle: confirmTitle,
            confirmRole: confirmRole,
            layout: layout,
            systemImage: systemImage,
            tint: tint,
            titleFont: titleFont,
            onCancel: onCancel,
            onConfirm: onConfirm,
            details: { EmptyView() },
            extra: extra
        )
    }
}

package extension InlineConfirmation where Details == EmptyView, Extra == EmptyView {

    init(
        _ title: String,
        confirmTitle: String,
        confirmRole: ButtonRole?,
        layout: Layout = .line,
        systemImage: String? = "exclamationmark.triangle.fill",
        tint: Color = .red,
        titleFont: Font = .caption,
        onCancel: @escaping () -> Void,
        onConfirm: @escaping () -> Void
    ) {
        self.init(
            title,
            confirmTitle: confirmTitle,
            confirmRole: confirmRole,
            layout: layout,
            systemImage: systemImage,
            tint: tint,
            titleFont: titleFont,
            onCancel: onCancel,
            onConfirm: onConfirm,
            details: { EmptyView() },
            extra: { EmptyView() }
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        InlineConfirmation(
            "Erase all content and settings on iPhone 16? The simulator shuts down first.",
            confirmTitle: "Erase",
            confirmRole: .destructive,
            onCancel: {},
            onConfirm: {}
        )
        InlineConfirmation(
            "Delete worktree ABC-2600?",
            confirmTitle: "Delete",
            confirmRole: .destructive,
            layout: .stacked(warnings: ["3 uncommitted changes will be lost"]),
            onCancel: {},
            onConfirm: {}
        ) {
            Toggle("Delete DerivedData (1.2 GB)", isOn: .constant(true))
        }
        InlineConfirmation(
            "Rebase on develop? Local changes are stashed and restored.",
            confirmTitle: "Rebase",
            confirmRole: nil,
            tint: .orange,
            onCancel: {},
            onConfirm: {}
        )
    }
    .padding(14)
    .frame(width: 640)
}
