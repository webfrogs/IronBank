//
//  DownloadHelper.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 08/12/2017.
//

import Foundation

public struct DownloadInfo: Codable {
    let url: URL
    let name: String
    let hooks: Hooks?

    public struct Hooks: Codable {
        let after: [String]?
    }
}


extension DownloadHelper {
    static func download(info: DownloadInfo) throws {
        print("Downloading \(info.name)".green)

        let downloadedFolder = try IronBankKit.center.downloadedFolderPath()
            .appendingPathComponent(info.name)
        _ = try? FileManager.default.removeItem(at: downloadedFolder)

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

        // Run hook.
        for shell in info.hooks?.after ?? [] {
            let shellResult = Process.ib.syncRun(shell: shell, currentDir: downloadedFolder.path)

            guard shellResult == EX_OK else {
                throw IronBankKit.Errors.Download.hookFailed(shell: shell)
            }
        }

    }
}

class DownloadHelper {

}
