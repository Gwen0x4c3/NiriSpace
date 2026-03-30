@testable import AppBundle
import Common
import XCTest

@MainActor
final class CycleSizeCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testParseCommand() {
        testParseCommandSucc("cycle-size 33% 50% 66%", CycleSizeCmdArgs(rawArgs: [], presets: [33, 50, 66]))
        testParseCommandFail("cycle-size 33", msg: "ERROR: Can't parse '33'. Width must be specified as percentage like '50%'")
        testParseCommandFail("cycle-size 0%", msg: "ERROR: Width percentage must be greater than 0")
    }

    func testCycleSizeCyclesSortedPresetsInNiri() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        let window1 = TestWindow.new(id: 1, parent: root, adaptiveWeight: 480)
        _ = window1.focusWindow()
        TestWindow.new(id: 2, parent: root, adaptiveWeight: 900)

        let first = try await parseCommand("cycle-size 25% 50% 75%").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(first.exitCode, 0)
        assertEquals(window1.getWeight(.h), CGFloat(960))

        let second = try await parseCommand("cycle-size 25% 50% 75%").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(second.exitCode, 0)
        assertEquals(window1.getWeight(.h), CGFloat(1440))

        let third = try await parseCommand("cycle-size 25% 50% 75%").cmdOrDie.run(.defaultEnv, .emptyStdin)
        assertEquals(third.exitCode, 0)
        assertEquals(window1.getWeight(.h), CGFloat(480))
    }

    func testCycleSizeTargetsWholeNiriColumnForNestedContainer() async throws {
        config.defaultRootContainerLayout = .niri
        let workspace = Workspace.get(byName: name)
        let root = workspace.rootTilingContainer
        TestWindow.new(id: 1, parent: root, adaptiveWeight: 480)
        let column = TilingContainer.newVTiles(parent: root, adaptiveWeight: 960, index: INDEX_BIND_LAST).apply {
            TestWindow.new(id: 2, parent: $0)
            TestWindow.new(id: 3, parent: $0).focusWindow()
        }

        let result = try await parseCommand("cycle-size 25% 50% 75%").cmdOrDie.run(.defaultEnv, .emptyStdin)

        assertEquals(result.exitCode, 0)
        assertEquals(column.getWeight(.h), CGFloat(1440))
        assertEquals(column.children[0].getWeight(.v), CGFloat(1))
        assertEquals(column.children[1].getWeight(.v), CGFloat(1))
    }
}
