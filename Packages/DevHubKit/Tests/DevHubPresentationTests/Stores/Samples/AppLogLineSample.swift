import DevHubDomain

enum AppLogLineSample {
    static let debug = AppLogLine(id: 1, date: nil, level: .debug, category: "net", message: "debug line")
    static let error = AppLogLine(id: 2, date: nil, level: .error, category: "net", message: "error line")
}
