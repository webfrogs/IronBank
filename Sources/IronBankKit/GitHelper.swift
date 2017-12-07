import Foundation
import CryptoSwift
import Rainbow

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

    func checkout(addr: String, ref: String, toFolderPath: String) throws {
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

class GitHelper {
    static let standard = GitHelper()
    private init() {}
}

// MARK: - ** Extension: Private Methods **
private extension GitHelper {

}


