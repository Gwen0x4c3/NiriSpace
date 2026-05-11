import AppKit
import Common

struct FullscreenCommand: Command {
    let args: FullscreenCmdArgs
    /*conforms*/ let shouldResetClosedWindowsCache = false

    func run(_ env: CmdEnv, _ io: CmdIo) -> BinaryExitCode {
        guard let target = args.resolveTargetOrReportError(env, io) else { return .fail }
        guard let window = target.windowOrNil else {
            return .fail(io.err(noWindowIsFocused))
        }
        if let niriContainer = window.parents.compactMap({ $0 as? TilingContainer }).first(where: { $0.layout == .niri }),
           let workspace = window.nodeWorkspace,
           let niriColumn = window.directChild(of: niriContainer)
        {
            return toggleNiriColumnFullscreen(window, column: niriColumn, in: niriContainer, workspace: workspace, io)
        }
        let newState: Bool = switch args.toggle {
            case .on: true
            case .off: false
            case .toggle: !window.isFullscreen
        }
        if newState == window.isFullscreen {
            return switch args.failIfNoop {
                case true: .fail
                case false:
                    .succ(io.err((newState ? "Already fullscreen. " : "Already not fullscreen. ") +
                            "Tip: use --fail-if-noop to exit with non-zero code"))
            }
        }
        window.isFullscreen = newState
        window.noOuterGapsInFullscreen = args.noOuterGaps

        // Focus on its own workspace
        window.markAsMostRecentChild()
        return .succ
    }

    @MainActor
    private func toggleNiriColumnFullscreen(_ window: Window, column: TreeNode, in container: TilingContainer, workspace: Workspace, _ io: CmdIo) -> BinaryExitCode {
        let currentWidth = column.getWeight(.h)
        let fullscreenWidth = workspace.workspaceMonitor.visibleRectPaddedByOuterGaps.width
        var savedWidth = column.getUserData(key: Window.niriPreFullscreenWidthKey)
        if savedWidth != nil && abs(currentWidth - fullscreenWidth) > 1 {
            column.cleanUserData(key: Window.niriPreFullscreenWidthKey)
            savedWidth = nil
        }
        let isFullscreen = savedWidth != nil

        let shouldFullscreen: Bool = switch args.toggle {
            case .on: true
            case .off: false
            case .toggle: !isFullscreen
        }

        if shouldFullscreen == isFullscreen {
            return switch args.failIfNoop {
                case true: .fail
                case false:
                    .succ(io.err((shouldFullscreen ? "Already fullscreen. " : "Already not fullscreen. ") +
                            "Tip: use --fail-if-noop to exit with non-zero code"))
            }
        }

        if shouldFullscreen {
            window.isFullscreen = false
            column.putUserData(key: Window.niriPreFullscreenWidthKey, data: currentWidth)
            column.setWeight(.h, fullscreenWidth)
        } else {
            column.setWeight(.h, savedWidth ?? workspace.niriDefaultColumnWidth)
            column.cleanUserData(key: Window.niriPreFullscreenWidthKey)
        }

        if NiriAnimationDriver.shared.isAnimating(container: container) {
            NiriAnimationDriver.shared.stopAnimation()
        } else {
            container.cleanUserData(key: TilingContainer.niriAnimatedOffsetKey)
        }
        if NiriWindowAnimationDriver.shared.isAnimating(container: container) {
            NiriWindowAnimationDriver.shared.stopAnimation()
        }
        window.markAsMostRecentChild()
        return .succ
    }
}

let noWindowIsFocused = "No window is focused"

extension Window {
    static let niriPreFullscreenWidthKey = TreeNodeUserDataKey<CGFloat>(key: "niriPreFullscreenWidthKey")
}
