import Foundation
import DevHubDomain
import DevHubUI

enum DoctorRowMapper {

    static func model(for status: ToolStatus) -> DoctorRowModel {
        let tool = status.tool
        guard let path = status.path else {
            return DoctorRowModel(id: tool.name, name: tool.name, purpose: tool.purpose, stateText: "missing", stateTint: .orange, icon: "exclamationmark.triangle.fill", path: nil, installCommand: tool.installCommand)
        }
        if let version = status.version, let minimum = tool.minimumMajorVersion, DoctorPolicy.isBelow(minimumMajorVersion: minimum, version: version) {
            return DoctorRowModel(
                id: tool.name,
                name: tool.name,
                purpose: tool.purpose,
                stateText: "\(version), needs \(minimum) or newer",
                stateTint: .orange,
                icon: "exclamationmark.triangle.fill",
                path: ProjectPath(path).abbreviated,
                installCommand: tool.upgradeCommand ?? tool.installCommand
            )
        }
        return DoctorRowModel(
            id: tool.name,
            name: tool.name,
            purpose: tool.purpose,
            stateText: status.version ?? "found, no version",
            stateTint: status.version == nil ? .orange : .green,
            icon: status.version == nil ? "questionmark.circle" : "checkmark.circle.fill",
            path: ProjectPath(path).abbreviated,
            installCommand: status.version == nil ? tool.installCommand : nil
        )
    }

    static func accessibility(isTrusted: Bool) -> DoctorRowModel {
        DoctorRowModel(
            id: "accessibility",
            name: "Accessibility",
            purpose: "Run & Attach clicks Debug → Attach to Process in Xcode",
            stateText: isTrusted ? "allowed" : "not allowed",
            stateTint: isTrusted ? .green : .orange,
            icon: isTrusted ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            path: nil,
            installCommand: nil
        )
    }

    static func notifications(_ permission: NotificationPermission) -> DoctorRowModel {
        let text = switch permission {
        case .allowed: "allowed"
        case .denied: "denied"
        case .notAsked: "not asked"
        }
        return DoctorRowModel(
            id: "notifications",
            name: "Notifications",
            purpose: "Build results and review requests while the panel is closed",
            stateText: text,
            stateTint: permission == .allowed ? .green : .orange,
            icon: permission == .allowed ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
            path: nil,
            installCommand: nil
        )
    }
}
