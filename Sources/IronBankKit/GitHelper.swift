import Foundation
import CryptoSwift
import Rainbow

public struct GitInfo: Decodable {

    func checkoutFolderPath() throws -> URL {
        let projectCheckoutPath = try IronBankKit.center.gitCheckoutPath()

        let checkoutPath = projectCheckoutPath.appendingPathComponent(name)
        try? FileManager.default.removeItem(at: checkoutPath)
        try checkoutPath.ib.createDirectoryIfNotExist()

        return checkoutPath
    }

    let remote: String
    let version: String
    let name: String

    enum CodingKeys: String, CodingKey {
        case remote
        case version
        case name
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        remote = try values.decode(String.self, forKey: .remote)

        // version is optional.
        do {
            version = try values.decode(String.self, forKey: .version)
                .hand.trimWhitespaceAndNewline()
        } catch {
            version = "master"
        }

        // name is optional.
        do {
            name = try values.decode(String.self, forKey: .name)
        } catch {
            guard let addrURL = URL(string: remote) else {
                throw IronBankKit.Errors.Git.repoNameGenerateFailed(addr: remote)
            }
            var result = addrURL.lastPathComponent
            let trimedSuffix = ".git"
            if result.hasSuffix(trimedSuffix) {
                result = result.hand.substring(to: result.count - trimedSuffix.count)
            }
            name = result
        }
    }
}


extension GitHelper {
    func fetch(addr: String) throws {
        let addrMD5 = addr.md5()
        let gitRepoCacheFolderPath = try URL.ib.gitLocalCacheFolderPath()
        let repoCachePath = gitRepoCacheFolderPath.appendingPathComponent(addrMD5)

        let gitCommand: String
        let shellWorkPath: String
        if FileManager.default.fileExists(atPath: repoCachePath.path) {
            gitCommand = "git fetch --prune --quiet "
                + addr
                + " 'refs/tags/*:refs/tags/*' '+refs/heads/*:refs/heads/*'"
            shellWorkPath = repoCachePath.path
            print("Fetching \(addr)".green)
        } else {
            gitCommand = "git clone --bare \(addr) \(addrMD5)"
            shellWorkPath = gitRepoCacheFolderPath.path
            print("Cloing \(addr)".green)
        }

        guard Process.ib.syncRun(shell: gitCommand, currentDir: shellWorkPath) == EX_OK else {
            throw IronBankKit.Errors.Git.fetchFailed(addr: addr)
        }
    }

    func checkout(info: GitInfo) throws {
        try p_checkout(info: info)
    }

}

class GitHelper {
    static let standard = GitHelper()
    private init() {}

    private let kVersionRegex = "^(\\d+\\.)?(\\d+\\.)?(\\d+)$"
}

// MARK: - ** Extension: Private Methods **
private extension GitHelper {
    func p_checkout(info: GitInfo) throws {
        let repoCachePath = try URL.ib.gitLocalCacheFolderPath()
            .appendingPathComponent(info.remote.md5())
        if !FileManager.default.fileExists(atPath: repoCachePath.path) {
            // if cache is not found, fetch first.
            try fetch(addr: info.remote)
        }

        let toFolderPath = try info.checkoutFolderPath().path
        let gitEnv = ["GIT_WORK_TREE": toFolderPath]

        let checkoutRef = try p_calculateProperRef(info: info
            , shellDir: repoCachePath.path
            , shellEnv: gitEnv)

        let command = "git reset --hard \(checkoutRef)"

        let shellResult = Process.ib.syncRun(shell: command
            , currentDir: repoCachePath.path
            , envrionment: gitEnv)

        guard shellResult == EX_OK else {
            throw IronBankKit.Errors.Git.checkoutFailed(addr: info.remote)
        }
    }

    func p_calculateProperRef(info: GitInfo, shellDir: String, shellEnv: [String: String]) throws
    -> String {
        guard info.version.hasPrefix("~>") else {
            return info.version
        }

        let configVersion = info.version.hand.substring(from: "~>".count)
            .hand.trimWhitespaceAndNewline()
        guard configVersion.hand.match(regex: kVersionRegex) else {
            throw IronBankKit.Errors.Config.versionInvalid(info)
        }
        let splitConfigVersion = try configVersion.split(separator: ".")
            .map { (text) -> Int in
                guard let result = Int(text) else {
                    throw IronBankKit.Errors.Config.versionInvalid(info)
                }
                return result
            }

        var result: (ref: String, didFind: Bool) = ("master", false)
        defer {
            if result.didFind {
                print("Find version \(result.ref).".green)
            } else {
                print("Warning: No version matched with '\(info.version)',"
                    + " use \(result.ref) instead. Check the \(info.name) in Bankfile.yml file."
                        .yellow)
            }
        }

        let shell = "git tag"

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", shell]
        task.currentDirectoryPath = shellDir
        task.environment = shellEnv

        let pipe = Pipe()
        task.standardOutput = pipe
        task.launch()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        task.waitUntilExit()

        guard let output = String(data: data, encoding: String.Encoding.utf8) else {
            return result.ref
        }

        let gitVersions = output.split(separator: "\n")
        print(gitVersions)
        let sortedVersion = gitVersions
            .filter({$0.hand.match(regex: self.kVersionRegex)})
            .sorted { (first, second) -> Bool in
                return second.compare(first, options: .numeric) == .orderedDescending
            }

        let versionNotOlder = sortedVersion
            .filter({
                $0.compare(configVersion, options: .numeric) == .orderedDescending ||
                    $0.compare(configVersion, options: .numeric) == .orderedSame
            })

        guard versionNotOlder.count > 1 else {
            return result.ref
        }

        let maxVersion: String?
        switch splitConfigVersion.count {
        case 2:
            maxVersion = "\(splitConfigVersion[0]+1)" + ".0"
        case 3:
            maxVersion = "\(splitConfigVersion[0])" + ".\(splitConfigVersion[1] + 1)" + ".0"
        default:
            maxVersion = nil
        }

        if let maxVersion = maxVersion
        , let validVersion = versionNotOlder
            .filter({ $0.compare(maxVersion, options: .numeric) == .orderedAscending }).last {
            // maxVersion is not included.
            result = (String(validVersion), true)
        }

        return result.ref
    }

}


