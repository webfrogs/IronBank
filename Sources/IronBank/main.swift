import Foundation
import IronBankKit
import Commander

#if !os(macOS)
Logger.logError("IronBank only support for macOS now.")
exit(EX_OSERR)
#endif

let version = "0.0.1-beta.1"

let group = Group()

group.command("install", description: "Install all dependences.") {
    do {
        try IronBankKit.center.install()
    } catch {
        switch error {
        case let IronBankKit.Errors.Config.fileNotFound(filename):
            // check configuation file
            Logger.logError("\(filename) is not found.")
        default:
            print(error)
        }
        exit(EX_CONFIG)
    }
}

group.command("version", description: "Show current version.") {
    Logger.logInfo("Current version: \(version)")
}

group.run()

