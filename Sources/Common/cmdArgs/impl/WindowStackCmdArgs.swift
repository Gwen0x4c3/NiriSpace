public struct WindowStackCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .windowStack,
        allowInConfig: true,
        help: window_stack_help_generated,
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

func parseWindowStackCmdArgs(_ args: StrArrSlice) -> ParsedCmd<WindowStackCmdArgs> {
    parseSpecificCmdArgs(WindowStackCmdArgs(rawArgs: args), args)
}

public struct MoveColumnCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .moveColumn,
        allowInConfig: true,
        help: move_column_help_generated,
        flags: [
            "--window-id": windowIdSubArgParser(),
        ],
        posArgs: [newMandatoryPosArgParser(\.direction, parseMoveColumnDirectionArg, placeholder: Direction.unionLiteral)],
    )

    public var direction: Lateinit<Direction> = .uninitialized

    public init(rawArgs: [String], direction: Direction, windowId: UInt32? = nil) {
        self.commonState = .init(rawArgs.slice)
        self.direction = .initialized(direction)
        self.windowId = windowId
    }

    public enum Direction: String, CaseIterable, Equatable, Sendable {
        case left, right
    }
}

func parseMoveColumnCmdArgs(_ args: StrArrSlice) -> ParsedCmd<MoveColumnCmdArgs> {
    parseSpecificCmdArgs(MoveColumnCmdArgs(rawArgs: args), args)
}

private func parseMoveColumnDirectionArg(i: PosArgParserInput) -> ParsedCliArgs<MoveColumnCmdArgs.Direction> {
    .init(parseEnum(i.arg, MoveColumnCmdArgs.Direction.self), advanceBy: 1)
}
