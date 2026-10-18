import Foundation
import DevHubDomain
import DevHubUI

enum LaunchProfileMapper {
    static let maxSegments = 4
    static let productionTag = TagModel(
        "production",
        tint: .red,
        systemImage: "exclamationmark.triangle.fill",
        hint: "This profile uses the production server: real data and real users"
    )

    static func model(profiles: [LaunchProfile], selected: LaunchProfile?) -> LaunchProfileModel? {
        guard let selected else { return nil }
        return LaunchProfileModel(
            options: profiles.map { LaunchProfileModel.Option(id: $0.id, title: $0.title, isProduction: $0.isProduction) },
            selectedID: selected.id,
            usesSegments: profiles.count <= maxSegments,
            summary: summary(selected),
            details: details(selected),
            productionTag: selected.isProduction ? productionTag : nil
        )
    }

    private static func summary(_ profile: LaunchProfile) -> String {
        var parts = (profile.env ?? [:]).sorted { $0.key < $1.key }.map { "\($0.key)=\($0.value)" }
        if let args = profile.args, args.isEmpty == false {
            parts.append(CountText.count(args.count, "argument"))
        }
        if let defaults = profile.defaults, defaults.isEmpty == false {
            parts.append(CountText.count(defaults.count, "default"))
        }
        if profile.cleanInstall == true {
            parts.append("clean install")
        }
        return parts.isEmpty ? "No environment, arguments or defaults" : parts.joined(separator: " · ")
    }

    private static func details(_ profile: LaunchProfile) -> String {
        var lines = (profile.env ?? [:]).sorted { $0.key < $1.key }.map { "env \($0.key)=\($0.value)" }
        lines += (profile.args ?? []).map { "arg \($0)" }
        lines += (profile.defaults ?? []).map { "default \($0.suite) · \($0.key) = \($0.value)" }
        if profile.cleanInstall == true {
            lines.append("clean install before every launch")
        }
        return lines.isEmpty ? "This profile sets nothing." : lines.joined(separator: "\n")
    }
}
