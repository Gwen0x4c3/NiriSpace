import AppKit
import Common

struct WindowStackCommand: Command {
    let args: WindowStackCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return io.err(noWindowIsFocused) }
        guard let (root, column) = niriRootColumn(for: window) else {
            return io.err("window-stack currently works only for windows inside niri layout")
        }
        guard column == window else {
            return io.err("window-stack currently works only when the focused window is already its own niri column")
        }
        guard let ownIndex = column.ownIndex, ownIndex > 0 else {
            return io.err("No left neighbour column to stack into")
        }

        let leftNeighbour = root.children[ownIndex - 1]
        let stackColumn: TilingContainer
        if let existing = leftNeighbour as? TilingContainer, existing.orientation == .v, existing.layout == .tiles {
            stackColumn = existing
        } else {
            let leftBinding = leftNeighbour.unbindFromParent()
            stackColumn = TilingContainer(
                parent: root,
                adaptiveWeight: leftBinding.adaptiveWeight,
                .v,
                .tiles,
                index: leftBinding.index,
            )
            leftNeighbour.bind(to: stackColumn, adaptiveWeight: WEIGHT_AUTO, index: INDEX_BIND_LAST)
        }

        _ = window.unbindFromParent()
        window.bind(to: stackColumn, adaptiveWeight: WEIGHT_AUTO, index: INDEX_BIND_LAST)
        return true
    }
}

@MainActor
func niriRootColumn(for window: Window) -> (root: TilingContainer, column: TreeNode)? {
    guard let column = window.parentsWithSelf.first(where: { ($0.parent as? TilingContainer)?.layout == .niri }) else {
        return nil
    }
    guard let root = column.parent as? TilingContainer, root.layout == .niri else {
        return nil
    }
    return (root, column)
}
