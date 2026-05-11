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
