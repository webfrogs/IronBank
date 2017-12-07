//
//  URL+Extensions.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 07/12/2017.
//

import Foundation

extension URL: NamespaceWrappable {}
extension NamespaceWrapper where T == URL {
    static func cacheRootPath() throws -> URL {
        let userCacheDir = try FileManager.default.url(for: .cachesDirectory
            , in: .userDomainMask
            , appropriateFor: nil
            , create: true)
        let result = userCacheDir.appendingPathComponent("IronBank")
        try result.ib.createDirectoryIfNotExist()
        return result
    }

    static func gitLocalCacheFolderPath() throws -> URL {
        let cacheRoot = try cacheRootPath()
        let result = cacheRoot.appendingPathComponent("git-repositories")
        do {
            try result.ib.createDirectoryIfNotExist()
        } catch {
            throw IronBankKit.Errors.Git.localCacheFolderCreateFailed
        }

        return result
    }

    func createDirectoryIfNotExist() throws {
        if !FileManager.default.fileExists(atPath: wrappedValue.path) {
            try FileManager.default.createDirectory(at: wrappedValue, withIntermediateDirectories: true, attributes: nil)
        }
    }

}
