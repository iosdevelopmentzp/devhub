import Testing
@testable import DevHubPresentation

@Suite struct StatusItemTitleTests {
    @Test(arguments: [
        (String?.none, Int?.none, ""),
        ("45%", nil, " 45%"),
        (nil, 3, " 3 MR"),
        ("45%", 3, " 45% · 3 MR"),
        ("45%", 0, " 45%"),
        (nil, 0, ""),
    ])
    func title(usage: String?, reviewCount: Int?, text: String) {
        #expect(StatusItemTitle.text(usage: usage, reviewCount: reviewCount) == text)
    }
}
