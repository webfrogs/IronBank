import Foundation
import Rainbow

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
let currentPath = FileManager.default.currentDirectoryPath


// check configuation file


// do the right thing


