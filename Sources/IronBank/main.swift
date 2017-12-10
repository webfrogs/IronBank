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
        case let IronBankKit.Errors.Config.downloadURLInvalid(info):
            let msg = "Download url wrong, only support http and https."
                + " Check the url of \(info.name) in \(IronBankKit.center.configFileName)."
            Logger.logError(msg)
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

