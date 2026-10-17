import SwiftUI

struct RunBarProfile: View {
    @Environment(BuildStore.self) private var build

    private var selection: Binding<String> {
        Binding(
            get: { build.profile?.id ?? "" },
            set: { value in build.setOptions { $0.profileID = value } }
        )
    }

    private var pairs: [(String, String)] {
        guard let profile = build.profile else { return [] }
        var list: [(String, String)] = []
        for key in (profile.env ?? [:]).keys.sorted() {
            list.append(("env", "\(key)=\(profile.env?[key] ?? "")"))
        }
        for argument in profile.args ?? [] {
            list.append(("arg", argument))
        }
        for item in profile.defaults ?? [] {
            list.append(("default", "\(item.suite) · \(item.key) = \(item.value)"))
        }
        return list
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text("Profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Launch profile", selection: selection) {
                    ForEach(build.profiles) { profile in
                        Text(profile.title).tag(profile.id)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .controlSize(.small)
                .fixedSize()
            }
            if pairs.isEmpty {
                Text("This profile sets no environment variables, arguments or defaults.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                KeyValueBlock(pairs: pairs)
                    .font(.caption.monospaced())
            }
        }
    }
}

#Preview {
    RunBarProfile()
        .padding()
        .previewEnvironment()
}
