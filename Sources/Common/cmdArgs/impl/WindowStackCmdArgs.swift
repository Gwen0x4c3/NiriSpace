public struct WindowStackCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .windowStack,
        allowInConfig: true,
        help: window_stack_help_generated,
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

func parseWindowStackCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WindowStackCmdArgs> {
    parseSpecificCmdArgs(WindowStackCmdArgs(rawArgs: args), args)
}
