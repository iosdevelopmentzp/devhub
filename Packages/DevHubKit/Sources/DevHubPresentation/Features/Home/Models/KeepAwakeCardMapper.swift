import Foundation
import DevHubUI

enum KeepAwakeCardMapper {
    static func model(isActive: Bool) -> KeepAwakeCardModel {
        guard isActive else {
            return KeepAwakeCardModel(
                isActive: false,
                title: "Keep Mac awake",
                subtitle: "Off. The Mac sleeps as usual",
                systemImage: "moon.zzz.fill",
                tint: .gray
            )
        }
        return KeepAwakeCardModel(
            isActive: true,
            title: "Keep Mac awake",
            subtitle: "On until you turn it off or quit DevHub",
            systemImage: "cup.and.saucer.fill",
            tint: .orange
        )
    }
}
