import SwiftUI

struct UsageDetails: View {
    let id: UsageProviderID
    let entry: UsageEntry
    let refresh: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            if let usage = entry.usage {
                ForEach(usage.meters) { meter in
                    Text(line(for: meter))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let note = usage.note {
                    Text(note).font(.caption).foregroundStyle(.secondary)
                }
                if let plan = usage.plan {
                    Text("Plan: \(plan)").font(.caption).foregroundStyle(.secondary)
                }
            }
            HStack(spacing: 8) {
                if let updated = entry.updatedAt {
                    Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Button("Refresh", action: refresh)
                    .controlSize(.small)
                    .disabled(entry.isLoading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, 62)
    }

    private func line(for meter: UsageMeter) -> String {
        var parts = [meter.title]
        if let detail = meter.detail {
            parts.append(detail)
        }
        if let resets = meter.resetsAt {
            parts.append("resets \(resets.formatted(.relative(presentation: .named))) (\(resets.formatted(date: .abbreviated, time: .shortened)))")
        }
        return parts.joined(separator: " · ")
    }
}

#Preview {
    UsageDetails(id: .claude, entry: UsageEntry(usage: ProviderUsage(meters: [UsageMeter(id: "a", title: "Session", percent: 4, resetsAt: Date(), detail: nil)], plan: "Max", note: nil)), refresh: {})
        .padding()
}
