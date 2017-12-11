import Foundation
import CryptoSwift
import Rainbow

public struct GitInfo: Decodable {
    let remote: String
    let version: String
    let name: String
    let build: BuildType?

    enum CodingKeys: String, CodingKey {
        case remote
        case version
        case name
        case build
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

        // build is optional
        var builder: BuildType? = nil
        do {
            builder = try values.decode(XcodeBuild.self, forKey: .build)
        } catch IronBankKit.Errors.Build.typeNotMatch {
            throw IronBankKit.Errors.Build.typeNotSupport
        } catch {
            throw error
        }

        build = builder
    }

    func checkoutFolderPath() throws -> URL {
        let projectCheckoutPath = try IronBankKit.center.gitCheckoutPath()
        let checkoutPath = projectCheckoutPath.appendingPathComponent(name)

        return checkoutPath
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
            Logger.logInfo("Fetching \(addr)")
        } else {
            gitCommand = "git clone --bare \(addr) \(addrMD5)"
            shellWorkPath = gitRepoCacheFolderPath.path
            Logger.logInfo("Cloing \(addr)")
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

        let checkoutPath = try info.checkoutFolderPath()
        // clear checkout folder. Checkout folder should exist, or git checkout will fail.
        try? FileManager.default.removeItem(at: checkoutPath)
        try checkoutPath.ib.createDirectoryIfNotExist()

        let gitEnv = ["GIT_WORK_TREE": checkoutPath.path]

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
            throw IronBankKit.Errors.Config.gitVersionInvalid(info)
        }
        let splitConfigVersion = try configVersion.split(separator: ".")
            .map { (text) -> Int in
                guard let result = Int(text) else {
                    throw IronBankKit.Errors.Config.gitVersionInvalid(info)
                }
                return result
            }

        var result: (ref: String, didFind: Bool) = ("master", false)
        defer {
            if result.didFind {
                Logger.logInfo("Find version \(result.ref)")
            } else {
                Logger.logWarning("Warning: No version matched with '\(info.version)',"
                    + " use \(result.ref) instead. Check the \(info.name) in Bankfile.yml file.")
            }
        }

        let shell = "git tag"

        guard let output = Process.ib.syncRunWithOutput(shell: shell
            , currentDir: shellDir
            , envrionment: shellEnv) else {
            return result.ref
        }

        let gitVersions = output.split(separator: "\n")
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


