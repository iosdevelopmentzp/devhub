import SwiftUI

struct ScriptHeaderHint: View {
    private static let example = """
    #!/bin/zsh
    # devhub: title = Regenerate resources
    # devhub: subtitle = What it does in one line
    # devhub: icon = wand.and.stars
    # devhub: tint = purple
    # devhub: input = target, Target, choice, App|Widget
    # devhub: input = clean, Clean first, toggle, false
    # devhub: placements = home.scripts, git.pills
    # devhub: confirm = Continue?
    # devhub: cwd = main
    # devhub: refresh = git
    """

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Header lines in the first 20 lines of an executable file")
                .font(.callout.weight(.semibold))
            Text(Self.example)
                .font(.caption.monospaced())
                .textSelection(.enabled)
            Text("The file name is the title when there is no header. Run chmod +x on the file. Print @devhub lines to drive the UI. See docs/extensions.md.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(width: 440)
    }
}

#Preview {
    ScriptHeaderHint()
}
