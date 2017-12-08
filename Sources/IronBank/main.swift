import Foundation
import Rainbow
import IronBankKit
import Commander

#if !os(macOS)
print("IronBank only support for macOS now.".red)
exit(EX_OSERR)
#endif

let version = "0.0.1-beta"

let group = Group()

group.command("install", description: "Install all dependences.") {
    do {
        try IronBankKit.center.install()
    } catch {
        switch error {
        case let IronBankKit.Errors.Config.fileNotFound(filename):
            // check configuation file
            print("\(filename) is not found.".red)
        default:
            print(error)
        }
        exit(EX_CONFIG)
    }
}

group.command("version", description: "Show current version.") {
    print("Version: \(version)")
}

group.run()

