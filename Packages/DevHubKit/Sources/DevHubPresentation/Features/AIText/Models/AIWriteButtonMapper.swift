import Foundation
import DevHubDomain

enum AIWriteButtonMapper {
    static func model(title: String, purpose: String, defaultProvider: AIProvider, isRunning: Bool, isEnabled: Bool) -> AIWriteButtonModel {
        let tool = AISessionRowMapper.toolTitle(for: defaultProvider)
        return AIWriteButtonModel(
            title: title,
            hint: "\(tool) \(purpose). The arrow picks the other tool for one run; Settings sets the default.",
            defaultProvider: defaultProvider,
            choices: ([defaultProvider] + AIProvider.allCases.filter { $0 != defaultProvider }).map { provider in
                AIWriteButtonModel.Choice(id: provider, title: AISessionRowMapper.toolTitle(for: provider) + (provider == defaultProvider ? " (default)" : ""))
            },
            isRunning: isRunning,
            isEnabled: isEnabled,
            stopHint: "Stop the AI tool"
        )
    }
}
