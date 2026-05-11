import AppKit
import Common

struct WindowUnstackCommand: Command {
    let args: WindowUnstackCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = true

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard let stack = window.parent as? TilingContainer,
              stack.orientation == .v,
              stack.layout == .tiles,
              let root = stack.parent as? TilingContainer,
              root.layout == .niri,
              let stackIndex = stack.ownIndex
        else {
            return .fail(io.err("window-unstack currently works only for windows inside a stacked niri column"))
        }

        let width = stack.getWeight(.h)
        _ = window.unbindFromParent()
        window.bind(to: root, adaptiveWeight: width, index: stackIndex + 1)
        return .succ
    }
}
