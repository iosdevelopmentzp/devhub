import SwiftUI

struct GitDiffView: View {
    let diff: GitDiff

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if diff.isBinary {
                Label("Binary file: there is no text diff to show.", systemImage: "doc.zipper")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if diff.lines.isEmpty {
                Text("No text changes (for example only the file mode changed).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(diff.lines.enumerated()), id: \.offset) { _, line in
                            Text(line.isEmpty ? " " : line)
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundStyle(color(for: line))
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(background(for: line))
                        }
                    }
                }
                .frame(maxHeight: 320)
                .background(Theme.base, in: RoundedRectangle(cornerRadius: 6))
            }
            if diff.hiddenLineCount > 0 {
                Text("\(diff.hiddenLineCount) more lines are not shown (limit \(GitDiff.lineLimit)).")
                    .font(.caption)
                    .foregroundStyle(Tint.orange.color)
            }
        }
    }

    private func color(for line: String) -> Color {
        if line.hasPrefix("+++") || line.hasPrefix("---") || line.hasPrefix("diff ") || line.hasPrefix("index ") {
            return .secondary
        }
        if line.hasPrefix("@@") { return Tint.blue.color }
        if line.hasPrefix("+") { return Tint.green.color }
        if line.hasPrefix("-") { return Tint.red.color }
        return .primary
    }

    private func background(for line: String) -> Color {
        if line.hasPrefix("+++") || line.hasPrefix("---") { return .clear }
        if line.hasPrefix("+") { return Tint.green.color.opacity(0.1) }
        if line.hasPrefix("-") { return Tint.red.color.opacity(0.1) }
        return .clear
    }
}

#Preview {
    GitDiffView(diff: GitDiff(text: "@@ -1,2 +1,3 @@\n context\n-old\n+new\n"))
        .padding()
}
