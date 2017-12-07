//
//  IronBankKit.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 07/12/2017.
//

import Foundation
import Rainbow
import HandOfTheKing

public extension IronBankKit {
    func install() throws {
        let projectCheckoutPath = try p_gitCheckoutPath()
        
        try configFile().items.forEach({ (item) in
            if case let .git(addr) = item {
                // Fetch git repository to local.
                try GitHelper.standard.fetch(addr: addr)
                let repoName = try self.p_getGitRepoName(addr: addr)

                // Checkout files from git to a specific project path
                let checkoutPath = projectCheckoutPath.appendingPathComponent(repoName)
                try? FileManager.default.removeItem(at: checkoutPath)
                try checkoutPath.ib.createDirectoryIfNotExist()

                // TODO: Checkout the right version from git.
                try GitHelper.standard
                    .checkout(addr: addr, ref: "master", toFolderPath: checkoutPath.path)
            }
        })



    }

}

public class IronBankKit {
    public static let center = IronBankKit()
    private init() {}

    public enum Errors: Error {
        case configFileNotFound(filename: String)

        public enum Git: Error {
            case localCacheFolderCreateFailed
            case fetchFailed(addr: String)
            case checkoutFailed(addr: String)
            case repoNameGenerateFailed(addr: String)
        }
    }

    private var _configFile: ConfigFileType?

    private let kConfigFileName = "Bankfile"
    private let kCurrentPath: URL = {
        #if DEBUG
            return try! FileManager.default.url(for: .desktopDirectory
                , in: .userDomainMask
                , appropriateFor: nil
                , create: true)
        #else
            return URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        #endif
    }()

}

extension IronBankKit {
    func configFile() throws -> ConfigFileType {
        if let cache = _configFile {
            return cache
        }

        let configFilePath = kCurrentPath.appendingPathComponent(kConfigFileName)
        guard FileManager.default.fileExists(atPath: configFilePath.path) else {
            throw Errors.configFileNotFound(filename: kConfigFileName)
        }
        let result = try ConfigFileFactory.newModel(path: configFilePath.path)
        _configFile = result
        return result
    }
}

private extension IronBankKit {
    func p_workPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    func p_gitCheckoutPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Checkouts")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    func p_getGitRepoName(addr: String) throws -> String {
        guard let addrURL = URL(string: addr) else {
            throw IronBankKit.Errors.Git.repoNameGenerateFailed(addr: addr)
        }
        var result = addrURL.lastPathComponent
        let trimedSuffix = ".git"
        if result.hasSuffix(trimedSuffix) {
            result = result.hand.substring(to: result.count - trimedSuffix.count)
        }

        return result
    }
}
