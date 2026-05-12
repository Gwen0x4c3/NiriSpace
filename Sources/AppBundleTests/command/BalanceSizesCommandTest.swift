@testable import AppBundle
import Common
import XCTest

@MainActor
final class BalanceSizesCommandTest: XCTestCase {
    override func setUp() async throws { setUpWorkspacesForTests() }

    func testBalanceSizesCommand() async throws {
        let workspace = Workspace.get(byName: name).apply { wsp in
            wsp.rootTilingContainer.apply {
                TestWindow.new(id: 1, parent: $0).setWeight(wsp.rootTilingContainer.orientation, 1)
                TestWindow.new(id: 2, parent: $0).setWeight(wsp.rootTilingContainer.orientation, 2)
                TestWindow.new(id: 3, parent: $0).setWeight(wsp.rootTilingContainer.orientation, 3)
            }
        }

        try await BalanceSizesCommand(args: BalanceSizesCmdArgs(rawArgs: []))
            .run(.defaultEnv.copy(\.workspaceName, name), .emptyStdin)

        for window in workspace.rootTilingContainer.children {
            assertEquals(window.getWeight(workspace.rootTilingContainer.orientation), 1)
        }
    }

    func testBalanceSizesResetsNiriColumnsToConfiguredDefaultWidth() async throws {
        config.defaultRootContainerLayout = .niri
        config.niriDefaultColumnWidthPercent = 50

        let workspace = Workspace.get(byName: name)
        let window1 = TestWindow.new(id: 1, parent: workspace)
        try await window1.relayoutWindow(on: workspace, forceTile: true)
        let window2 = TestWindow.new(id: 2, parent: workspace)
        try await window2.relayoutWindow(on: workspace, forceTile: true)

        let root = workspace.rootTilingContainer
        root.children[0].setWeight(.h, 700)
        root.children[1].setWeight(.h, 1200)

        try await BalanceSizesCommand(args: BalanceSizesCmdArgs(rawArgs: []))
            .run(.defaultEnv.copy(\.workspaceName, name), .emptyStdin)

        let expectedWidth = workspace.niriDefaultColumnWidth
        assertEquals(root.children[0].getWeight(.h), expectedWidth)
        assertEquals(root.children[1].getWeight(.h), expectedWidth)
    }
}
