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
        try configFile().items.forEach({ (item) in
            switch item {
            case let .git(info):
                // Fetch git repository to local.
                try GitHelper.standard.fetch(addr: info.remote)

                // Checkout files from git to a specific project path
                try GitHelper.standard.checkout(info: info)
            case let .download(info):
                print("Downloading \(info.name)".green)

                var downloadSuccess = false

                let semaphore = DispatchSemaphore(value: 0)
                let downloadTask = URLSession.shared.downloadTask(with: info.url) {
                    (file, response, error) in
                    defer {
                        semaphore.signal()
                    }

                    guard let httpResponse = response as? HTTPURLResponse
                    , let tmpFilePath = file
                    , error == nil
                    , 200..<300 ~= httpResponse.statusCode
                    else {
                        return
                    }

                    do {
                        let downloadedFolder = try self.downloadedFolderPath()
                            .appendingPathComponent(info.name)
                        _ = try? FileManager.default.removeItem(at: downloadedFolder)
                        try downloadedFolder.ib.createDirectoryIfNotExist()
                        let movePath = downloadedFolder
                            .appendingPathComponent(info.url.lastPathComponent)
                        try FileManager.default.moveItem(at: tmpFilePath, to: movePath)
                    } catch {
                        return
                    }

                    downloadSuccess = true
                }
                downloadTask.resume()
                _ = semaphore.wait(timeout: .now() + 60)

                guard downloadSuccess else {
                    throw IronBankKit.Errors.Download.failed(info)
                }
            }
        })
    }

}

public class IronBankKit {
    public static let center = IronBankKit()
    private init() {}

    public enum Errors: Error {
        public enum Config: Error {
            case fileNotFound(filename: String)
            case fileIsNotUTF8Encoding
            case typeNotSupported
            case notYaml
        }

        public enum Download: Error {
            case failed(DownloadInfo)
        }

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
            throw Errors.Config.fileNotFound(filename: kConfigFileName)
        }
        let result = try ConfigFileFactory.newModel(path: configFilePath.path)
        _configFile = result
        return result
    }

    func gitCheckoutPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Checkouts")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    func downloadedFolderPath() throws -> URL {
        let result = kCurrentPath.appendingPathComponent("IronBank/Downloaded")
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
