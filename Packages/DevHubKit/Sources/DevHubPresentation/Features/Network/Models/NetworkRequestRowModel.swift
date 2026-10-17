import Foundation
import DevHubDomain
import DevHubUI

struct NetworkRequestRowModel: Identifiable, Equatable {
    let id: NetworkRequest.ID
    var method: String
    var methodTint: Tint
    var path: String
    var host: String
    var status: String
    var statusTint: Tint
    var statusHint: String
    var duration: String
    var durationTint: Tint
    var time: String
    var tags: [TagModel]
    var isSelected: Bool

    static let preview = NetworkRequestRowModel(
        id: 1,
        method: "GET",
        methodTint: .blue,
        path: "/v1/profile/info",
        host: "api-qa.example.com",
        status: "200",
        statusTint: .green,
        statusHint: "200 no error",
        duration: "182 ms",
        durationTint: .secondary,
        time: "14:02:17.384",
        tags: [NetworkRequestRowMapper.mockedTag],
        isSelected: false
    )
}
