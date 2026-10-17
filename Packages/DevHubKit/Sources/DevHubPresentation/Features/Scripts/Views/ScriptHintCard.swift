import SwiftUI
import DevHubDomain
import DevHubUI

struct ScriptHintCard: View {
    private let example = """
    #!/bin/zsh
    # devhub: title = Regenerate resources
    # devhub: subtitle = What it does in one line
    # devhub: icon = wand.and.stars
    # devhub: tint = purple
    # devhub: input = target, Target, choice, App|Widget
    # devhub: placements = home.scripts, git.pills
    # devhub: confirm = Continue?
    # devhub: refresh = git
    """

    var body: some View {
        PanelCard {
            VStack(alignment: .leading, spacing: 8) {
                Label("Add your own", systemImage: "lightbulb")
                    .font(.callout.weight(.medium))
                Text("Any executable file in .devhub/scripts becomes a row here: in the project, in ~/.devhub/projects/<folder> or in ~/.devhub. Header lines in the first 20 lines set the title, inputs and placements. Run chmod +x on the file. Print @devhub lines to drive the panel. See docs/extensions.md.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(example)
                    .font(.caption.monospaced())
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.base, in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .textSelection(.enabled)
            }
        }
    }
}

#Preview {
    ScriptHintCard()
        .padding()
}
