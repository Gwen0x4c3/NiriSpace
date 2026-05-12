@testable import AppBundle
import Common
import XCTest

@MainActor
final class WindowStackCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseWindowStackCommands() {
        XCTAssertTrue(parseCommand("window-stack").cmdOrNil is WindowStackCommand)
        XCTAssertTrue(parseCommand("window-unstack").cmdOrNil is WindowUnstackCommand)
        XCTAssertTrue(parseCommand("move-column left").cmdOrNil is MoveColumnCommand)
        XCTAssertTrue(parseCommand("move-column right").cmdOrNil is MoveColumnCommand)
        XCTAssertNil(parseCommand("move-column up").cmdOrNil)
        XCTAssertTrue(parseCommand("niri-toggle-tags").cmdOrNil is NiriToggleTagsCommand)
    }

    func testWindowStackInNiri() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TestWindow.new(id: 1, parent: root)
        TestWindow.new(id: 2, parent: root)
        XCTAssertTrue(TestWindow.new(id: 3, parent: root).focusWindow())

        let result = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(1), .v_tiles([.window(2), .window(3)])]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testWindowStackReusesExistingLeftStack() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TestWindow.new(id: 1, parent: root)
        TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0)
        }
        XCTAssertTrue(TestWindow.new(id: 4, parent: root).focusWindow())

        let result = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(1), .v_tiles([.window(2), .window(3), .window(4)])]))
        assertEquals(focus.windowOrNil?.windowId, 4)
    }

    func testWindowStackReusesExistingTaggedLeftStack() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TilingContainer(parent: root, adaptiveWeight: 1, .v, .tabbed).apply {
            TestWindow.new(id: 1, parent: $0)
            TestWindow.new(id: 2, parent: $0)
        }
        XCTAssertTrue(TestWindow.new(id: 3, parent: root).focusWindow())

        let result = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.v_tabbed([.window(1), .window(2), .window(3)])]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testWindowUnstackInNiri() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TestWindow.new(id: 1, parent: root)
        TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
            TestWindow.new(id: 2, parent: $0)
            XCTAssertTrue(TestWindow.new(id: 3, parent: $0).focusWindow())
        }

        let result = try await parseCommand("window-unstack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(1), .v_tiles([.window(2)]), .window(3)]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testWindowStackRequiresNiriAndLeftNeighbour() async throws {
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        XCTAssertTrue(TestWindow.new(id: 1, parent: root).focusWindow())

        let nonNiri = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(nonNiri.exitCode, 1)

        workspace.rootTilingContainer.layout = .niri
        let noLeftNeighbour = try await parseCommand("window-stack").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(noLeftNeighbour.exitCode, 1)
    }

    func testWindowUnstackRequiresStackedNiriColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        XCTAssertTrue(TestWindow.new(id: 1, parent: root).focusWindow())
        TestWindow.new(id: 2, parent: root)

        let result = try await parseCommand("window-unstack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 1)
        assertEquals(root.layoutDescription, .niri([.window(1), .window(2)]))
    }

    func testMoveColumnMovesWholeStackedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TestWindow.new(id: 1, parent: root)
        TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
            TestWindow.new(id: 2, parent: $0)
            XCTAssertTrue(TestWindow.new(id: 3, parent: $0).focusWindow())
        }
        TestWindow.new(id: 4, parent: root)

        let result = try await parseCommand("move-column right").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(1), .window(4), .v_tiles([.window(2), .window(3)])]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testMoveColumnInsertsWindowColumnBesideStackedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
            TestWindow.new(id: 1, parent: $0)
            TestWindow.new(id: 2, parent: $0)
        }
        XCTAssertTrue(TestWindow.new(id: 3, parent: root).focusWindow())
        TestWindow.new(id: 4, parent: root)

        let result = try await parseCommand("move-column left").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(3), .v_tiles([.window(1), .window(2)]), .window(4)]))
        assertEquals(focus.windowOrNil?.windowId, 3)
    }

    func testMoveColumnRequiresNiriAndHorizontalNeighbour() async throws {
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        XCTAssertTrue(TestWindow.new(id: 1, parent: root).focusWindow())

        let nonNiri = try await parseCommand("move-column left").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(nonNiri.exitCode, 1)

        workspace.rootTilingContainer.layout = .niri
        let noLeftNeighbour = try await parseCommand("move-column left").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(noLeftNeighbour.exitCode, 1)
    }

    func testNiriToggleTagsTogglesStackedColumnBetweenTilesAndTabbed() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TilingContainer.newVTiles(parent: root, adaptiveWeight: 1).apply {
            TestWindow.new(id: 1, parent: $0)
            XCTAssertTrue(TestWindow.new(id: 2, parent: $0).focusWindow())
            TestWindow.new(id: 3, parent: $0)
        }

        let enable = try await parseCommand("niri-toggle-tags").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(enable.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.v_tabbed([.window(1), .window(2), .window(3)])]))
        assertEquals(focus.windowOrNil?.windowId, 2)

        let disable = try await parseCommand("niri-toggle-tags").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(disable.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.v_tiles([.window(1), .window(2), .window(3)])]))
    }

    func testWindowUnstackWorksFromTaggedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TilingContainer(parent: root, adaptiveWeight: 1, .v, .tabbed).apply {
            TestWindow.new(id: 1, parent: $0)
            XCTAssertTrue(TestWindow.new(id: 2, parent: $0).focusWindow())
        }

        let result = try await parseCommand("window-unstack").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.v_tabbed([.window(1)]), .window(2)]))
    }

    func testNiriToggleTagsRequiresStackedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        XCTAssertTrue(TestWindow.new(id: 1, parent: root).focusWindow())

        let result = try await parseCommand("niri-toggle-tags").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 1)
        assertEquals(root.layoutDescription, .niri([.window(1)]))
    }

    func testFocusUpDownInsideTaggedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let root = Workspace.get(byName: name).rootTilingContainer
        TilingContainer(parent: root, adaptiveWeight: 1, .v, .tabbed).apply {
            TestWindow.new(id: 1, parent: $0)
            XCTAssertTrue(TestWindow.new(id: 2, parent: $0).focusWindow())
            TestWindow.new(id: 3, parent: $0)
        }

        try await parseCommand("focus down").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 3)

        try await parseCommand("focus up").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(focus.windowOrNil?.windowId, 2)
    }

    func testTaggedColumnLayoutShowsOnlyFocusedWindow() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        var window1: Window!
        var window2: Window!
        var window3: Window!
        TilingContainer(parent: root, adaptiveWeight: 1, .v, .tabbed).apply {
            window1 = TestWindow.new(id: 1, parent: $0)
            window2 = TestWindow.new(id: 2, parent: $0)
            window3 = TestWindow.new(id: 3, parent: $0)
        }
        XCTAssertTrue(window2.focusWindow())

        try await workspace.layoutWorkspace()

        assertEquals(window2.rectForTests?.topLeftX, root.children[0].rectForTests?.topLeftX)
        XCTAssertGreaterThan(window1.rectForTests?.topLeftX ?? 0, mainMonitor.rect.maxX)
        XCTAssertGreaterThan(window3.rectForTests?.topLeftX ?? 0, mainMonitor.rect.maxX)
    }
}
