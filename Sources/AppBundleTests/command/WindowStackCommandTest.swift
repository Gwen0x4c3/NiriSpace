@testable import AppBundle
import Common
import XCTest

@MainActor
final class WindowStackCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseWindowStackCommands() {
        XCTAssertTrue(parseCommand("window-stack").cmdOrNil is WindowStackCommand)
        XCTAssertTrue(parseCommand("window-unstack").cmdOrNil is WindowUnstackCommand)
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
}
