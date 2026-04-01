import Common
import Foundation

let configDotfileName = ".aerospace.toml"
let niriSpaceConfigDotfileName = ".nirispace.toml"
func findCustomConfigUrl() -> ConfigFile {
    let home = FileManager.default.homeDirectoryForCurrentUser
    let xdgConfigHome = ProcessInfo.processInfo.environment["XDG_CONFIG_HOME"].map { URL(filePath: $0) }
        ?? home.appending(path: ".config/")
    let candidates: [URL] = switch serverArgs.configLocation {
        case .some(let configLocation): [URL(filePath: configLocation)]
        case nil:
            [
                home.appending(path: niriSpaceConfigDotfileName),
                home.appending(path: configDotfileName),
                xdgConfigHome.appending(path: "aerospace").appending(path: "aerospace.toml"),
            ]
    }
    let existingCandidates: [URL] = candidates.filter { (candidate: URL) in FileManager.default.fileExists(atPath: candidate.path) }
    let count = existingCandidates.count
    return switch count {
        case 0: .noCustomConfigExists
        case 1: .file(existingCandidates.first.orDie())
        default: .ambiguousConfigError(existingCandidates)
    }
}

enum ConfigFile {
    case file(URL), ambiguousConfigError(_ candidates: [URL]), noCustomConfigExists

    var urlOrNil: URL? {
        return switch self {
            case .file(let url): url
            case .ambiguousConfigError, .noCustomConfigExists: nil
        }
    }
}
