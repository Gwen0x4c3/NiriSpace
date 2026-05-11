import AppKit
import Common

struct CycleSizeCommand: Command {
    let args: CycleSizeCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard let column = window.parentsWithSelf.first(where: { ($0.parent as? TilingContainer)?.layout == .niri }) else {
            return .fail(io.err("cycle-size currently works only for windows inside niri layout"))
        }
        guard let workspace = column.nodeWorkspace else { return .fail }

        let currentWidth = column.getWeight(.h)
        let orderedWidths = args.presets.val.map(workspace.niriColumnWidth(percent:))
        guard let nextWidth = nextCycleSize(currentWidth: currentWidth, orderedWidths: orderedWidths) else {
            return .fail
        }
        column.cleanUserData(key: Window.niriPreFullscreenWidthKey)
        column.setWeight(.h, nextWidth)
        return .succ
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
