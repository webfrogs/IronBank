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

        var buildList: [ConfigItem] = []
        try configFile().items.forEach({ (item) in
            switch item {
            case let .git(info):
                // Fetch git repository to local.
                try GitHelper.standard.fetch(addr: info.remote)

                // Checkout files from git to a specific project path
                try GitHelper.standard.checkout(info: info)

                if info.build != nil {
                    buildList.append(item)
                }
            case let .download(info):
                try DownloadHelper.download(info: info)
            }
        })

        // Build
        for item in buildList {
            switch item {
            case let .git(info):
                try info.build?.build(item: item)
            case .download:
                break
            }
        }
    }

}

public class IronBankKit {
    public static let center = IronBankKit()
    private init() {}

    public let configFileName = "Bankfile.yml"

    public enum Errors: Error {
        public enum Config: Error {
            case fileNotFound(filename: String)
            case fileIsNotUTF8Encoding
            case typeNotSupported
            case notYaml
            case gitVersionInvalid(GitInfo)
            case downloadURLInvalid(DownloadInfo)
        }

        public enum Download: Error {
            case failed(DownloadInfo)
            case hookFailed(shell: String)
        }

        public enum Git: Error {
            case localCacheFolderCreateFailed
            case fetchFailed(addr: String)
            case checkoutFailed(addr: String)
            case repoNameGenerateFailed(addr: String)
        }

        public enum Build: Error {
            case projectNotFound
            case projectCannotParsed
            case typeInvalid
            case configInfoWrong(String)
            case buildFailed
        }
    }

    private var _configFile: ConfigFileType?

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

        let configFilePath = kCurrentPath.appendingPathComponent(configFileName)
        guard FileManager.default.fileExists(atPath: configFilePath.path) else {
            throw Errors.Config.fileNotFound(filename: configFileName)
        }

        let result: ConfigFileType
        do {
            result = try ConfigFileFactory.newModel(path: configFilePath.path)
        } catch {
            if case let DecodingError.dataCorrupted(context) = error
            , let underlyingError = context.underlyingError {
                throw underlyingError
            } else {
                throw error
            }

        }

        _configFile = result
        return result
    }

    func gitCheckoutPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Checkouts")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    func downloadedFolderPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Downloads")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    func buildFolderPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Builds")
        try result.ib.createDirectoryIfNotExist()
        return result
    }
}

private extension IronBankKit {
    func p_workPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank")
        try result.ib.createDirectoryIfNotExist()
        return result
    }
}
