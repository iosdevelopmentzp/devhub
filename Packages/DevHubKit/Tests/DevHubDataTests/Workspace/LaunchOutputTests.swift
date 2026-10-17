import Testing
@testable import DevHubData

@Suite struct LaunchOutputTests {
    @Test(arguments: [
        ("com.example.app: 4242\n", Int32(4242)),
        ("4242", 4242),
        ("com.example.app:  77 ", 77),
    ])
    func readsPid(output: String, expected: Int32) {
        #expect(LaunchOutput.pid(from: output) == expected)
    }

    @Test(arguments: ["", "garbage", "com.example.app: ", "com.example.app: 12a"])
    func returnsNilWithoutPid(output: String) {
        #expect(LaunchOutput.pid(from: output) == nil)
    }
}
