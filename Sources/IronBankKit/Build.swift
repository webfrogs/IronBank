//
//  Build.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 10/12/2017.
//

import Foundation

protocol BuildType: Codable {
    func build(item: ConfigItem) throws
}

struct XcodeBuild: BuildType {
    func build(item: ConfigItem) throws {
        switch item {
        case let .git(info):
            let checkoutPath = try info.checkoutFolderPath()
            guard FileManager.default.fileExists(atPath: checkoutPath.path) else {
                throw IronBankKit.Errors.Build.projectNotFound
            }



        case let .download(info):
            break
        }
    }
}
