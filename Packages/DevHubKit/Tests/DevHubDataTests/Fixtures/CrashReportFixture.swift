import Foundation

enum CrashReportFixture {
    static let simulatorID = "8A1F0C2E-5B6D-4E7F-9A0B-1C2D3E4F5A6B"

    static let simulatorCrash = """
    {"app_name":"ExampleApp","timestamp":"2026-11-01 14:05:09.00 +0200","app_version":"1.5.2","slice_uuid":"0b1c","build_version":"42","bug_type":"309","os_version":"macOS 26.1 (25B78)","bundleID":"com.example.app","name":"ExampleApp","incident_id":"F00D"}
    {
      "procPath" : "/Users/alex/Library/Developer/CoreSimulator/Devices/\(simulatorID)/data/Containers/Bundle/Application/1111/ExampleApp.app/ExampleApp",
      "procName" : "ExampleApp",
      "bundleInfo" : {"CFBundleShortVersionString" : "1.5.2", "CFBundleIdentifier" : "com.example.app"},
      "exception" : {"type" : "EXC_BREAKPOINT", "signal" : "SIGTRAP", "subtype" : "Trace/BPT trap: 5"},
      "asi" : {"libswiftCore.dylib" : ["ExampleApp/ProfileViewModel.swift:42: Fatal error: Unexpectedly found nil while unwrapping an Optional value"]},
      "faultingThread" : 1,
      "threads" : [
        {"frames" : [{"imageIndex" : 2, "symbol" : "mach_msg2_trap"}]},
        {"triggered" : true, "frames" : [
          {"imageIndex" : 0, "symbol" : "_assertionFailure(_:_:file:line:flags:)"},
          {"imageIndex" : 1, "symbol" : "ProfileViewModel.load()", "sourceFile" : "ProfileViewModel.swift", "sourceLine" : 42},
          {"imageIndex" : 1, "symbol" : "closure #1 in ProfileView.body.getter", "sourceFile" : "ProfileView.swift", "sourceLine" : 18},
          {"imageIndex" : 3}
        ]}
      ],
      "usedImages" : [
        {"name" : "libswiftCore.dylib", "path" : "/Library/Developer/CoreSimulator/Volumes/iOS_23A343/usr/lib/swift/libswiftCore.dylib"},
        {"name" : "ExampleApp.debug.dylib", "path" : "/Users/alex/Library/Developer/CoreSimulator/Devices/\(simulatorID)/data/Containers/Bundle/Application/1111/ExampleApp.app/ExampleApp.debug.dylib"},
        {"name" : "libsystem_kernel.dylib", "path" : "/usr/lib/system/libsystem_kernel.dylib"},
        {"path" : "/System/Library/Frameworks/SwiftUI.framework/SwiftUI"}
      ]
    }
    """

    static let macCrash = """
    {"app_name":"Notes","timestamp":"2026-11-01 14:06:00.00 +0200","bug_type":"309","bundleID":"com.example.notes","name":"Notes"}
    {"procPath" : "/Applications/Notes.app/Contents/MacOS/Notes", "exception" : {"type" : "EXC_CRASH", "signal" : "SIGABRT"}}
    """

    static let hang = """
    {"app_name":"ExampleApp","timestamp":"2026-11-01 14:07:00.00 +0200","bug_type":"298","bundleID":"com.example.app","name":"ExampleApp"}
    {"procPath" : "/Users/alex/Library/Developer/CoreSimulator/Devices/\(simulatorID)/data/Containers/Bundle/Application/1111/ExampleApp.app/ExampleApp"}
    """
}
