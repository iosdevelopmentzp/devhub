import Foundation

package struct MockUpstream: Hashable, Sendable {
    package var url: URL
    package var routes: [MockRoute] = []

    package init(url: URL, routes: [MockRoute] = []) {
        self.url = url
        self.routes = routes
    }

    package var host: String {
        url.host ?? url.absoluteString
    }

    package func url(forPath path: String) -> URL {
        routes
            .filter { path.hasPrefix($0.path) }
            .max { $0.path.count < $1.path.count }?
            .upstream ?? url
    }
}
