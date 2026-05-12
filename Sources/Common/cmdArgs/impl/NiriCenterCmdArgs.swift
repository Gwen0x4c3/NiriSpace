public struct NiriCenterCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .niriCenter,
        allowInConfig: true,
        help: niri_center_help_generated,
        flags: [:],
        posArgs: [],
    )
}

public struct NiriToggleTagsCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    public init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .niriToggleTags,
        allowInConfig: true,
        help: niri_toggle_tags_help_generated,
        flags: [
            "--window-id": windowIdSubArgParser(),
        ],
        posArgs: [],
    )

    public init(rawArgs: [String], windowId: UInt32? = nil) {
        self.commonState = .init(rawArgs.slice)
        self.windowId = windowId
    }
}
