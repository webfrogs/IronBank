import Foundation
import Rainbow
import IronBankKit

#if !os(macOS)
print("IronBank only support for macOS now.".red)
exit(EX_OSERR)
#endif

// check command argument
let args = CommandLine.arguments
guard args.count == 2 && args[1] == "install" else {
    print("See usage of IronBank.".red)
    exit(EX_USAGE)
}

// check whether git is installed


// do the right thing.
do {
    try IronBankKit.center.install()
} catch {
    switch error {
    case let IronBankKit.Errors.Config.fileNotFound(filename):
        // check configuation file
        print("No \(filename) found.".red)
    default:
        print(error)
    }

    exit(EX_CONFIG)
}


