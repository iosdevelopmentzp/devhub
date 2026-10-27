import Testing
@testable import DevHubPresentation

@Suite struct FavoriteOrderTests {
    @Test func movingDownPutsTheItemAfterTheTarget() {
        #expect(FavoriteOrder.moved(["a", "b", "c", "d"], id: "a", onto: "c") == ["b", "c", "a", "d"])
    }

    @Test func movingUpPutsTheItemBeforeTheTarget() {
        #expect(FavoriteOrder.moved(["a", "b", "c", "d"], id: "d", onto: "b") == ["a", "d", "b", "c"])
    }

    @Test func unknownIDsOrTheSameIDChangeNothing() {
        #expect(FavoriteOrder.moved(["a", "b"], id: "x", onto: "a") == ["a", "b"])
        #expect(FavoriteOrder.moved(["a", "b"], id: "a", onto: "x") == ["a", "b"])
        #expect(FavoriteOrder.moved(["a", "b"], id: "a", onto: "a") == ["a", "b"])
    }

    @Test func rankIsTheIndexOrTheEnd() {
        #expect(FavoriteOrder.rank(of: "b", in: ["a", "b"]) == 1)
        #expect(FavoriteOrder.rank(of: "x", in: ["a", "b"]) == 2)
    }
}
