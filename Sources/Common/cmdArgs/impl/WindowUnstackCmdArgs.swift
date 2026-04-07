public struct WindowUnstackCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .windowUnstack,
        allowInConfig: true,
        help: window_unstack_help_generated,
        flags: [
            "--window-id": optionalWindowIdFlag(),
        ],
        posArgs: [],
    )

    public init(rawArgs: [String], windowId: UInt32? = nil) {
        self.commonState = .init(rawArgs.slice)
        self.windowId = windowId
    }
}

func parseWindowUnstackCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WindowUnstackCmdArgs> {
    parseSpecificCmdArgs(WindowUnstackCmdArgs(rawArgs: args), args)
}
