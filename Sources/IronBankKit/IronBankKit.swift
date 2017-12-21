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
        var checkoutList: [GitCheckoutInfo] = []

        // Checkout or Download
        try? FileManager.default.removeItem(at: gitCheckoutPath())
        try? FileManager.default.removeItem(at: downloadedFolderPath())
        try configFile().items.forEach({ (item) in
            switch item {
            case let .git(info):
                // Fetch git repository to local.
                try GitHelper.standard.fetch(addr: info.remote)

                // Checkout files from git to a specific project path
                let checkoutInfo = try GitHelper.standard.checkout(info: info)
                checkoutList.append(checkoutInfo)

                if info.build != nil {
                    buildList.append(item)
                }
            case let .download(info):
                try DownloadHelper.download(info: info)
            }
        })

        // Make checkout resolve file.
        try? FileManager.default.removeItem(at: resolvedFilePath())
        let resolvedInfo = checkoutList
            .sorted { $0.name < $1.name }
            .map {$0.resolovedString()}
            .joined(separator: "\n\n")
        do {
            try resolvedInfo.write(to: resolvedFilePath()
                , atomically: true
                , encoding: String.Encoding.utf8)
        } catch {
            throw IronBankKit.Errors.Resolve.writeFailed
        }


        // Build
        try? FileManager.default.removeItem(at: buildFolderPath())
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
    public let resolvedFileName = "IronBank.resolved"

    public enum Errors: Error {
        public enum Config: Error {
            case fileNotFound(filename: String)
            case fileIsNotUTF8Encoding
            case typeNotSupported
            case notYaml
            case gitVersionInvalid(GitRepoInfo)
            case downloadURLInvalid(DownloadInfo)
        }

        public enum Resolve: Error {
            case writeFailed
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
            case typeNotMatch
            case typeNotSupport
            case configInfoWrong(String)
            case dependencyWrong
            case buildFailed
            case xcodeWorkspaceNotSupport
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

    func resolvedFilePath() throws -> URL {
        let resolvedFolerPath = kCurrentPath.appendingPathComponent("IronBank")
        try resolvedFolerPath.ib.createDirectoryIfNotExist()
        return resolvedFolerPath.appendingPathComponent(resolvedFileName)
    }
}

private extension IronBankKit {
    func p_workPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank")
        try result.ib.createDirectoryIfNotExist()
        return result
    }
}
