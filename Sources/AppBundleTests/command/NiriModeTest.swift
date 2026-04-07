@testable import AppBundle
import AppKit
import Common
import XCTest

@MainActor
final class NiriModeTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseNiriAndTabbedLayouts() {
        let command = parseCommand("layout niri tabbed h_tabbed v_tabbed scrolling-tiling tabs").cmdOrNil
        XCTAssertTrue(command is LayoutCommand)
        assertEquals(
            (command as! LayoutCommand).args.toggleBetween.val,
            [.niri, .tabbed, .h_tabbed, .v_tabbed, .niri, .tabbed],
        )
    }

    func testNewTilingWindowInsertedToTheRightOfFocusedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)

        let window1 = TestWindow.new(id: 1, parent: workspace)
        try await window1.relayoutWindow(on: workspace, forceTile: true)
        let window2 = TestWindow.new(id: 2, parent: workspace)
        try await window2.relayoutWindow(on: workspace, forceTile: true)

        XCTAssertTrue(window1.focusWindow())

        let window3 = TestWindow.new(id: 3, parent: workspace)
        try await window3.relayoutWindow(on: workspace, forceTile: true)

        assertEquals(workspace.rootTilingContainer.orientation, .h)
        assertEquals(workspace.rootTilingContainer.layoutDescription, .niri([.window(1), .window(3), .window(2)]))
    }

    func testNiriLayoutScrollsViewportToFocusedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)

        let window1 = TestWindow.new(id: 1, parent: workspace)
        try await window1.relayoutWindow(on: workspace, forceTile: true)
        let window2 = TestWindow.new(id: 2, parent: workspace)
        try await window2.relayoutWindow(on: workspace, forceTile: true)
        let window3 = TestWindow.new(id: 3, parent: workspace)
        try await window3.relayoutWindow(on: workspace, forceTile: true)

        XCTAssertTrue(window2.focusWindow())
        try await workspace.layoutWorkspace()

        assertEquals(window1.rectForTests?.topLeftX, CGFloat(-1344))
        assertEquals(window2.rectForTests?.topLeftX, CGFloat(192))
        assertEquals(window3.rectForTests?.topLeftX, CGFloat(1728))
        assertEquals(window2.rectForTests?.width, CGFloat(1536))
        assertEquals(window2.rectForTests?.height, CGFloat(1079))
    }

    func testSwitchingToNiriResetsExistingColumnWidthsToConfiguredDefault() async throws {
        config.niriDefaultColumnWidthPercent = 50
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        let window1 = TestWindow.new(id: 1, parent: root, adaptiveWeight: 300)
        _ = window1.focusWindow()
        TestWindow.new(id: 2, parent: root, adaptiveWeight: 1200)

        try await parseCommand("layout niri").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(root.layout, .niri)
        assertEquals(root.children[0].getWeight(.h), CGFloat(960))
        assertEquals(root.children[1].getWeight(.h), CGFloat(960))
    }

    func testLayoutTabbedOnJoinedColumn() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        let window1 = TestWindow.new(id: 1, parent: root)
        _ = window1.focusWindow()
        TestWindow.new(id: 2, parent: root)

        try await JoinWithCommand(args: JoinWithCmdArgs(rawArgs: [], direction: .right)).run(.defaultEnv, .emptyStdin)
        assertEquals(root.layoutDescription, .niri([.v_tiles([.window(1), .window(2)])]))

        try await parseCommand("layout tabbed").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(root.layoutDescription, .niri([.v_tabbed([.window(1), .window(2)])]))
    }

    func testMoveBoundaryKeepsNiriRootLayout() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        let window1 = TestWindow.new(id: 1, parent: root)
        _ = window1.focusWindow()
        TestWindow.new(id: 2, parent: root)

        let result = try await parseCommand("move up").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(root.layoutDescription, .niri([.window(1), .window(2)]))
    }

    func testHoverFocusDoesNotRecenterNiriViewport() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)

        let window1 = TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
        let window2 = TestWindow.new(id: 2, parent: workspace.rootTilingContainer)
        let window3 = TestWindow.new(id: 3, parent: workspace.rootTilingContainer)

        XCTAssertTrue(window2.focusWindow())
        try await workspace.layoutWorkspace()

        let window1X = window1.rectForTests?.topLeftX
        let window2X = window2.rectForTests?.topLeftX
        let window3X = window3.rectForTests?.topLeftX

        XCTAssertTrue(setFocus(to: LiveFocus(windowOrNil: window1, workspace: workspace), mode: .hoverWithoutRecentering))
        try await workspace.layoutWorkspace()

        assertEquals(focus.windowOrNil?.windowId, 1)
        assertEquals(window1.rectForTests?.topLeftX, window1X)
        assertEquals(window2.rectForTests?.topLeftX, window2X)
        assertEquals(window3.rectForTests?.topLeftX, window3X)
    }

    func testNormalFocusAfterHoverRecentersNiriViewport() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)

        let window1 = TestWindow.new(id: 1, parent: workspace.rootTilingContainer)
        let window2 = TestWindow.new(id: 2, parent: workspace.rootTilingContainer)
        let window3 = TestWindow.new(id: 3, parent: workspace.rootTilingContainer)

        XCTAssertTrue(window2.focusWindow())
        try await workspace.layoutWorkspace()

        let initialWindow1X = window1.rectForTests?.topLeftX
        let initialWindow2X = window2.rectForTests?.topLeftX
        let initialWindow3X = window3.rectForTests?.topLeftX

        XCTAssertTrue(setFocus(to: LiveFocus(windowOrNil: window1, workspace: workspace), mode: .hoverWithoutRecentering))
        try await workspace.layoutWorkspace()

        XCTAssertTrue(setFocus(to: LiveFocus(windowOrNil: window1, workspace: workspace)))
        try await workspace.layoutWorkspace()

        assertEquals(focus.windowOrNil?.windowId, 1)
        XCTAssertNotEqual(window1.rectForTests?.topLeftX, initialWindow1X)
        XCTAssertNotEqual(window2.rectForTests?.topLeftX, initialWindow2X)
        XCTAssertNotEqual(window3.rectForTests?.topLeftX, initialWindow3X)
        assertEquals(window1.rectForTests?.topLeftX, CGFloat(192))
    }
}
