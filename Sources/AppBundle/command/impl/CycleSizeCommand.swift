import AppKit
import Common

struct CycleSizeCommand: Command {
    let args: CycleSizeCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> Bool {
        guard let target = args.resolveTargetOrReportError(env, io) else { return false }
        guard let window = target.windowOrNil else { return io.err(noWindowIsFocused) }
        guard let column = window.parentsWithSelf.first(where: { ($0.parent as? TilingContainer)?.layout == .niri }) else {
            return io.err("cycle-size currently works only for windows inside niri layout")
        }
        guard let workspace = column.nodeWorkspace else { return false }

        let currentWidth = column.getWeight(.h)
        let orderedWidths = args.presets.val.map(workspace.niriColumnWidth(percent:))
        guard let nextWidth = nextCycleSize(currentWidth: currentWidth, orderedWidths: orderedWidths) else {
            return false
        }
        column.setWeight(.h, nextWidth)
        return true
    }
}

private let cycleSizeTolerance = CGFloat(1)

private func nextCycleSize(currentWidth: CGFloat, orderedWidths: [CGFloat]) -> CGFloat? {
    guard let firstWidth = orderedWidths.min() else { return nil }
    if let currentIndex = orderedWidths.firstIndex(where: { abs($0 - currentWidth) <= cycleSizeTolerance }) {
        return orderedWidths[(currentIndex + 1) % orderedWidths.count]
    }
    return orderedWidths.sorted().first(where: { $0 > currentWidth + cycleSizeTolerance }) ?? firstWidth
}
