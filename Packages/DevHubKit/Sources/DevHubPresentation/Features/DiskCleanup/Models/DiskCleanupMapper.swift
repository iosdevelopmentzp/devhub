import Foundation
import DevHubDomain
import DevHubUI

enum DiskCleanupMapper {
    static let singleKinds: [DiskCleanupKind] = [.staleDerivedData, .unavailableSimulators, .archives, .deviceSupport, .swiftPMCache, .cocoaPodsCache]

    static func model(
        items: [DiskCleanupItem],
        sizes: [DiskCleanupItem.ID: Int64],
        measuringIDs: Set<DiskCleanupItem.ID>,
        busyIDs: Set<DiskCleanupItem.ID>
    ) -> DiskCleanupModel {
        let row = { (item: DiskCleanupItem) in
            Self.row(for: item, size: sizes[item.id] ?? item.size, isMeasuring: measuringIDs.contains(item.id), isBusy: busyIDs.contains(item.id))
        }
        let rows = singleKinds.flatMap { kind in items.filter { $0.kind == kind } }.map(row)
        let projects = items.filter { $0.kind == .derivedData }.sorted { lhs, rhs in
            let left = sizes[lhs.id] ?? -1
            let right = sizes[rhs.id] ?? -1
            if left != right { return left > right }
            return DiskCleanupText.title(for: lhs).localizedStandardCompare(DiskCleanupText.title(for: rhs)) == .orderedAscending
        }
        let runtimes = items.filter { $0.kind == .simulatorRuntime }
        var groups: [DiskCleanupGroupModel] = []
        if projects.isEmpty == false {
            groups.append(group(.derivedData, icon: "hammer", title: "DerivedData by project", items: projects, sizes: sizes, noun: "project", rows: projects.map(row)))
        }
        if runtimes.isEmpty == false {
            groups.append(group(.simulatorRuntime, icon: "iphone.gen3", title: "Simulator runtimes", items: runtimes, sizes: sizes, noun: "runtime", rows: runtimes.map(row)))
        }
        let total = DiskCleanupPolicy.totalSize(of: items, sizes: sizes)
        return DiskCleanupModel(rows: rows, groups: groups, totalText: total > 0 ? "\(ByteFormat.text(total)) in total" : nil)
    }

    static func row(for item: DiskCleanupItem, size: Int64?, isMeasuring: Bool, isBusy: Bool) -> DiskCleanupRowModel {
        let title = DiskCleanupText.title(for: item)
        let sizeText = size.map(ByteFormat.text)
        return DiskCleanupRowModel(
            id: item.id,
            icon: icon(for: item.kind),
            title: title,
            detail: detail(for: item),
            sizeText: sizeText,
            isMeasuring: isMeasuring,
            isBusy: isBusy,
            canDelete: isBusy == false,
            deleteHint: "Deletes for good, not to the Trash: \(DiskCleanupText.command(for: item))",
            confirmTitle: "\(DiskCleanupText.operationTitle(for: item))\(sizeText.map { " (\($0))" } ?? "")?",
            warnings: warnings(for: item.kind) + ["This cannot be undone. Nothing goes to the Trash."]
        )
    }

    private static func group(_ kind: DiskCleanupKind, icon: String, title: String, items: [DiskCleanupItem], sizes: [DiskCleanupItem.ID: Int64], noun: String, rows: [DiskCleanupRowModel]) -> DiskCleanupGroupModel {
        let total = DiskCleanupPolicy.totalSize(of: items, sizes: sizes)
        let count = CountText.count(items.count, noun)
        return DiskCleanupGroupModel(id: kind, icon: icon, title: title, summary: total > 0 ? "\(count) · \(ByteFormat.text(total))" : count, rows: rows)
    }

    private static func icon(for kind: DiskCleanupKind) -> String {
        switch kind {
        case .staleDerivedData: "hammer.circle"
        case .derivedData: "hammer"
        case .unavailableSimulators: "iphone.slash"
        case .simulatorRuntime: "iphone.gen3"
        case .archives: "archivebox"
        case .deviceSupport: "cable.connector"
        case .swiftPMCache: "shippingbox"
        case .cocoaPodsCache: "cube.box"
        }
    }

    private static func detail(for item: DiskCleanupItem) -> String {
        switch item.kind {
        case .staleDerivedData:
            "\(CountText.count(item.count, "folder")) whose project is gone"
        case .derivedData:
            item.detail?.abbreviatingHome ?? ""
        case .unavailableSimulators:
            "\(CountText.count(item.count, "simulator")) whose runtime is not installed"
        case .simulatorRuntime:
            ["build \(item.detail ?? "?")", item.lastUsed.map { "used \($0.relativeDescription)" }].compactMap { $0 }.joined(separator: " · ")
        case .archives:
            "\(CountText.count(item.count, "folder")) in ~/Library/Developer/Xcode/Archives"
        case .deviceSupport:
            "\(CountText.count(item.count, "version")) · Xcode copies them again when a device connects"
        case .swiftPMCache:
            "~/Library/Caches/org.swift.swiftpm · packages download again on the next resolve"
        case .cocoaPodsCache:
            "~/Library/Caches/CocoaPods · pods download again on the next install"
        }
    }

    private static func warnings(for kind: DiskCleanupKind) -> [String] {
        switch kind {
        case .derivedData: ["The next build of this project starts from the beginning."]
        case .staleDerivedData: []
        case .unavailableSimulators: ["The data of these simulators is deleted too."]
        case .simulatorRuntime: ["Simulators of this runtime stop working until you install it again in Xcode → Settings → Components."]
        case .archives: ["Archives keep the dSYM files of shipped builds. Crash reports of those builds cannot be symbolicated after this."]
        case .deviceSupport: ["The next debug session on a device waits while Xcode copies its files again."]
        case .swiftPMCache, .cocoaPodsCache: []
        }
    }
}
