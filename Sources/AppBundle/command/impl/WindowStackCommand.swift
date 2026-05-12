import AppKit
import Common

struct WindowStackCommand: Command {
    let args: WindowStackCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard let (root, column) = niriRootColumn(for: window) else {
            return .fail(io.err("window-stack currently works only for windows inside niri layout"))
        }
        guard column == window else {
            return .fail(io.err("window-stack currently works only when the focused window is already its own niri column"))
        }
        guard let ownIndex = column.ownIndex, ownIndex > 0 else {
            return .fail(io.err("No left neighbour column to stack into"))
        }

        let leftNeighbour = root.children[ownIndex - 1]
        let stackColumn: TilingContainer
        if let existing = leftNeighbour as? TilingContainer,
           existing.orientation == .v,
           existing.layout == .tiles || existing.layout == .tabbed
        {
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
        return .succ
    }
}

struct MoveColumnCommand: Command {
    let args: MoveColumnCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard let (root, column) = niriRootColumn(for: window) else {
            return .fail(io.err("move-column currently works only for windows inside niri layout"))
        }
        guard let ownIndex = column.ownIndex else { return .fail }

        let targetIndex = switch args.direction.val {
            case .left: ownIndex - 1
            case .right: ownIndex + 1
        }
        guard root.children.indices.contains(targetIndex) else {
            return .fail(io.err("No \(args.direction.val.rawValue) neighbour column to move across"))
        }

        let niriAnimation = NiriMutationAnimation(window: window)
        let previousBinding = column.unbindFromParent()
        column.bind(to: root, adaptiveWeight: previousBinding.adaptiveWeight, index: targetIndex)
        window.markAsMostRecentChild()
        niriAnimation.startIfNeeded(.succ)
        return .succ
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
