public struct FocusCmdArgs: CmdArgs, Equatable {
    public static let info: CmdStaticInfo = RawFocusCmdArgs.info

    public let boundaries: Boundaries // todo cover boundaries wrapping with tests
    public let boundariesAction: WhenBoundariesCrossed
    public let direction: CardinalDirection

    public init(
        boundaries: Boundaries,
        boundariesAction: WhenBoundariesCrossed,
        direction: CardinalDirection
    ) {
        self.boundaries = boundaries
        self.boundariesAction = boundariesAction
        self.direction = direction
    }

    public enum Boundaries: String, CaseIterable, Equatable {
        case workspace
        case allMonitorsUnionFrame = "all-monitors-outer-frame"
    }
    public enum WhenBoundariesCrossed: String, CaseIterable, Equatable {
        case stop = "stop"
        case wrapAroundTheWorkspace = "wrap-around-the-workspace"
        case wrapAroundAllMonitors = "wrap-around-all-monitors"
    }
}

private struct RawFocusCmdArgs: RawCmdArgs {
    var boundaries: FocusCmdArgs.Boundaries = .workspace
    var boundariesAction: FocusCmdArgs.WhenBoundariesCrossed = .wrapAroundTheWorkspace
    var direction: Lateinit<CardinalDirection> = .uninitialized

    static let parser: CmdParser<Self> = cmdParser(
        kind: .focus,
        allowInConfig: true,
        help: """
              USAGE: focus [<OPTIONS>] \(CardinalDirection.unionLiteral)

              OPTIONS:
                -h, --help                     Print help
                --boundaries <boundary>        Defines focus boundaries.
                                               <boundary> possible values: \(FocusCmdArgs.Boundaries.unionLiteral)
                                               The default is: \(FocusCmdArgs.Boundaries.workspace.rawValue)
                --boundaries-action <action>   Defines the behavior when requested to cross the <boundary>.
                                               <action> possible values: \(FocusCmdArgs.WhenBoundariesCrossed.unionLiteral)
                                               The default is: \(FocusCmdArgs.WhenBoundariesCrossed.wrapAroundTheWorkspace.rawValue)

              ARGUMENTS:
                (left|down|up|right)           Focus direction
              """, // todo focus [OPTIONS] window-id <id>
        // ARGUMENTS:
        //  <id>                                  ID of window to focus
        options: [
            "--boundaries": ArgParser(\.boundaries, parseBoundaries),
            "--boundaries-action": ArgParser(\.boundariesAction, parseWhenBoundariesCrossed)
        ],
        arguments: [newArgParser(\.direction, parseCardinalDirectionArg, argPlaceholderIfMandatory: CardinalDirection.unionLiteral)]
    )
}

public func parseFocusCmdArgs(_ args: [String]) -> ParsedCmd<FocusCmdArgs> {
    parseRawCmdArgs(RawFocusCmdArgs(), args)
        .flatMap { raw in
            if raw.boundaries == .workspace && raw.boundariesAction == .wrapAroundAllMonitors {
                return .failure("\(raw.boundaries.rawValue) and \(raw.boundariesAction.rawValue) is an invalid combination of values")
            }
            return .cmd(FocusCmdArgs(
                boundaries: raw.boundaries,
                boundariesAction: raw.boundariesAction,
                direction: raw.direction.val
            ))
        }
}

private func parseWhenBoundariesCrossed(arg: String, nextArgs: inout [String]) -> Parsed<FocusCmdArgs.WhenBoundariesCrossed> {
    if let arg = nextArgs.nextOrNil() {
        return parseEnum(arg, FocusCmdArgs.WhenBoundariesCrossed.self)
    } else {
        return .failure("--boundaries-action option requires an argument: \(FocusCmdArgs.WhenBoundariesCrossed.unionLiteral)")
    }
}

private func parseBoundaries(arg: String, nextArgs: inout [String]) -> Parsed<FocusCmdArgs.Boundaries> {
    if let arg = nextArgs.nextOrNil() {
        return parseEnum(arg, FocusCmdArgs.Boundaries.self)
    } else {
        return .failure("--boundaries option requires an argument: \(FocusCmdArgs.Boundaries.unionLiteral)")
    }
}
