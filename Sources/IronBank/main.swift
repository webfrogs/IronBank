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


// check configuation file
let configFileName = "Bankfile"
let currentPath = FileManager.default.currentDirectoryPath
let configFilePath = URL(fileURLWithPath: currentPath).appendingPathComponent(configFileName)
let configFile: ConfigFileType
do {
    configFile = try ConfigFileFactory.newModel(path: configFilePath.path)
} catch {
    if case ConfigFileErrors.fileNotExist = error {
        print("No \(configFileName) found.".red)
    }
    exit(EX_CONFIG)
}


// do the right thing
configFile.update()


