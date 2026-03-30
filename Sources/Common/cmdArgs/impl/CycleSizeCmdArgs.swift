public struct CycleSizeCmdArgs: CmdArgs {
    /*conforms*/ public var commonState: CmdArgsCommonState
    fileprivate init(rawArgs: StrArrSlice) { self.commonState = .init(rawArgs) }
    public static let parser: CmdParser<Self> = .init(
        kind: .cycleSize,
        allowInConfig: true,
        help: cycle_size_help_generated,
        flags: [
            "--window-id": optionalWindowIdFlag(),
        ],
        posArgs: [newMandatoryPosArgParser(\.presets, parseCycleSizePresets, placeholder: "<width-percent>...")],
    )

    public var presets: Lateinit<[UInt]> = .uninitialized

    public init(rawArgs: [String], presets: [UInt]) {
        self.commonState = .init(rawArgs.slice)
        self.presets = .initialized(presets)
    }
}

func parseCycleSizeCmdArgs(_ args: StrArrSlice) -> ParsedCmd<CycleSizeCmdArgs> {
    parseSpecificCmdArgs(CycleSizeCmdArgs(rawArgs: args), args)
}

private func parseCycleSizePresets(input: PosArgParserInput) -> ParsedCliArgs<[UInt]> {
    let args = input.nonFlagArgs()
    var presets: [UInt] = []
    for (index, arg) in args.enumerated() {
        guard arg.hasSuffix("%"), let value = UInt(arg.dropLast()) else {
            return .fail("Can't parse '\(arg)'. Width must be specified as percentage like '50%'", advanceBy: index + 1)
        }
        guard value > 0 else {
            return .fail("Width percentage must be greater than 0", advanceBy: index + 1)
        }
        presets.append(value)
    }
    return .succ(presets, advanceBy: args.count)
}
