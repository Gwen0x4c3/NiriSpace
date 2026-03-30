import AppKit
import Common

struct ResizeCommand: Command { // todo cover with tests
    let args: ResizeCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }

        let candidates = target.windowOrNil?.parentsWithSelf
            .filter { ($0.parent as? TilingContainer)?.layout.keepsOwnWeights == true }
            ?? []

        func firstCandidate(with orientation: Orientation) -> TreeNode? {
            candidates.first(where: { ($0.parent as? TilingContainer)?.orientation == orientation })
        }

        let orientation: Orientation?
        let parent: TilingContainer?
        let node: TreeNode?
        switch args.dimension.val {
            case .width:
                orientation = .h
                node = firstCandidate(with: .h)
                parent = node?.parent as? TilingContainer
            case .height:
                orientation = .v
                node = firstCandidate(with: .v)
                parent = node?.parent as? TilingContainer
            case .smart:
                node = candidates.first(where: { ($0.parent as? TilingContainer)?.layout == .niri }) ?? candidates.first
                parent = node?.parent as? TilingContainer
                orientation = parent?.orientation
            case .smartOpposite:
                orientation = (candidates.first?.parent as? TilingContainer)?.orientation.opposite
                if let orientation {
                    node = firstCandidate(with: orientation)
                } else {
                    node = nil
                }
                parent = node?.parent as? TilingContainer
        }
        guard let parent else { return io.err("resize command doesn't support floating windows yet https://github.com/nikitabobko/AeroSpace/issues/9") }
        guard let orientation else { return false }
        guard let node else { return false }
        let diff: CGFloat = switch args.units.val {
            case .set(let unit): CGFloat(unit) - node.getWeight(orientation)
            case .add(let unit): CGFloat(unit)
            case .subtract(let unit): -CGFloat(unit)
        }

        switch parent.layout {
            case .tiles:
                guard let childDiff = diff.div(parent.children.count - 1) else { return false }
                parent.children.lazy
                    .filter { $0 != node }
                    .forEach { $0.setWeight(parent.orientation, $0.getWeight(parent.orientation) - childDiff) }
                node.setWeight(orientation, node.getWeight(orientation) + diff)
            case .niri:
                node.setWeight(orientation, node.getWeight(orientation) + diff)
            case .accordion, .tabbed:
                return false
        }
        return true
    }
}
