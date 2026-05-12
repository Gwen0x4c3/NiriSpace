import AppKit
import Common

struct NiriCenterCommand: Command {
    let args: NiriCenterCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let window = focus.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard window.parentsWithSelf.contains(where: { ($0.parent as? TilingContainer)?.layout == .niri }) else {
            return .fail(io.err("niri-center currently works only for windows inside niri layout"))
        }
        rememberCurrentNiriViewportAnchor()
        return .succ
    }
}

struct NiriToggleTagsCommand: Command {
    let args: NiriToggleTagsCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else { return .fail(io.err(noWindowIsFocused)) }
        guard let (_, column) = niriRootColumn(for: window) else {
            return .fail(io.err("niri-toggle-tags currently works only for windows inside niri layout"))
        }
        guard let stack = column as? TilingContainer, stack.orientation == .v else {
            return .fail(io.err("niri-toggle-tags currently works only for stacked niri columns"))
        }
        guard stack.children.count > 1 else {
            return .fail(io.err("niri-toggle-tags requires at least two windows in the column"))
        }

        switch stack.layout {
            case .tiles:
                stack.layout = .tabbed
            case .tabbed:
                stack.layout = .tiles
            case .accordion, .niri:
                return .fail(io.err("niri-toggle-tags currently works only for stacked niri columns"))
        }
        _ = window.focusWindow()
        return .succ
    }
}
