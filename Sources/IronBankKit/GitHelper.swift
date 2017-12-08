import Foundation
import CryptoSwift
import Rainbow

public struct GitInfo: Decodable {
    var ref: String {
        return "master"
    }

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
        version = try values.decode(String.self, forKey: .version)

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

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", gitCommand]
        task.currentDirectoryPath = shellWorkPath

        task.launch()
        task.waitUntilExit()

        guard task.terminationStatus == EX_OK else {
            throw IronBankKit.Errors.Git.fetchFailed(addr: addr)
        }
    }

    func checkout(info: GitInfo) throws {
        try p_checkout(addr: info.remote
            , ref: info.ref
            , toFolderPath: info.checkoutFolderPath().path)
    }

}

class GitHelper {
    static let standard = GitHelper()
    private init() {}
}

// MARK: - ** Extension: Private Methods **
private extension GitHelper {
    func p_checkout(addr: String, ref: String, toFolderPath: String) throws {
        let repoCachePath = try URL.ib.gitLocalCacheFolderPath().appendingPathComponent(addr.md5())
        if !FileManager.default.fileExists(atPath: repoCachePath.path) {
            try fetch(addr: addr)
        }

        let command = "git reset --hard \(ref)"

        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", command]
        task.currentDirectoryPath = repoCachePath.path
        task.environment = ["GIT_WORK_TREE": toFolderPath]

        task.launch()
        task.waitUntilExit()

        guard task.terminationStatus == EX_OK else {
            throw IronBankKit.Errors.Git.checkoutFailed(addr: addr)
        }

    }
}


