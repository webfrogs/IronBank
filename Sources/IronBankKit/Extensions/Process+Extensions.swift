//
//  Process+Extensions.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 08/12/2017.
//

import Foundation

extension Process: NamespaceWrappable {}
extension NamespaceWrapper where T: Process {
    static func syncRun(shell: String
        , currentDir: String? = nil
        , envrionment: [String: String] = [:]) -> Int32 {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", shell]
        if let path = currentDir, !path.isEmpty {
            task.currentDirectoryPath = path
        }
        if envrionment.count > 0 {
            task.environment = envrionment
        }

        task.launch()
        task.waitUntilExit()

        return task.terminationStatus
    }
}
