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
