import Testing
@testable import DevHubPresentation

@Suite struct ScriptListOrderTests {

    @Test func arrangedPutsFavoritesFirstThenFollowsTheSavedOrder() {
        let arranged = ScriptListOrder.arranged(ids: ["a", "b", "c", "d"], order: ["c", "a"], favorites: ["d"])

        #expect(arranged == ["d", "c", "a", "b"])
    }

    @Test func newScriptsKeepTheirConfigOrderAtTheEnd() {
        #expect(ScriptListOrder.arranged(ids: ["new1", "a", "new2"], order: ["a"], favorites: []) == ["a", "new1", "new2"])
    }

    @Test func movedWorksInsideOneGroup() {
        #expect(ScriptListOrder.moved(["a", "b", "c"], id: "c", onto: "b", favorites: ["a"]) == ["a", "c", "b"])
    }

    @Test func movedRefusesToCrossTheFavoriteGroup() {
        #expect(ScriptListOrder.moved(["a", "b", "c"], id: "c", onto: "a", favorites: ["a"]) == ["a", "b", "c"])
    }

    @Test func shiftedSwapsWithTheNeighbour() {
        #expect(ScriptListOrder.shifted(["a", "b", "c"], id: "b", by: 1, favorites: []) == ["a", "c", "b"])
        #expect(ScriptListOrder.shifted(["a", "b", "c"], id: "b", by: -1, favorites: []) == ["b", "a", "c"])
    }

    @Test func shiftedStopsAtTheEdgeAndAtTheGroupBorder() {
        #expect(ScriptListOrder.shifted(["a", "b"], id: "a", by: -1, favorites: []) == ["a", "b"])
        #expect(ScriptListOrder.shifted(["a", "b"], id: "b", by: -1, favorites: ["a"]) == ["a", "b"])
    }

    @Test func aNewFavoriteGoesToTheEndOfTheFavorites() {
        let result = ScriptListOrder.toggled(["a", "b", "c"], id: "c", favorites: ["a"])

        #expect(result.favorites == ["a", "c"])
        #expect(result.order == ["a", "c", "b"])
    }

    @Test func aRemovedFavoriteGoesToTheTopOfTheOthers() {
        let result = ScriptListOrder.toggled(["a", "b", "c"], id: "a", favorites: ["a", "b"])

        #expect(result.favorites == ["b"])
        #expect(result.order == ["b", "a", "c"])
    }

    @Test func toggledIgnoresAnUnknownID() {
        let result = ScriptListOrder.toggled(["a"], id: "x", favorites: [])

        #expect(result.order == ["a"])
        #expect(result.favorites.isEmpty)
    }
}
