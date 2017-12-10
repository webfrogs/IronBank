//
//  ConfigFile.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 05/12/2017.
//

import Foundation
import Yams

public protocol ConfigFileType {
    init(path: String) throws
    var items: [ConfigItem] { get }
}

public struct ConfigFileFactory {
    public static func newModel(path: String) throws -> ConfigFileType {
        return try YAMLConfigfile(path: path)
    }
}

struct YAMLConfigfile: ConfigFileType {
    let items: [ConfigItem]

    init(path: String) throws {

        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        } catch {
            throw IronBankKit.Errors.Config.fileIsNotUTF8Encoding
        }

        items = try YAMLDecoder().decode(from: fileContent)
    }
}

public enum ConfigItem: Decodable {
    case git(GitInfo)
    case download(DownloadInfo)

    enum CodingKeys: String, CodingKey {
        case git
        case download
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        do {
            let gitInfo = try container.decode(GitInfo.self, forKey: .git)
            self = .git(gitInfo)
            return
        } catch DecodingError.dataCorrupted(_) {
            throw IronBankKit.Errors.Config.notYaml
        } catch let DecodingError.keyNotFound(key, context)
            where key.stringValue != CodingKeys.git.stringValue {
            throw DecodingError.keyNotFound(key, context)
        } catch {
        }

        do {
            let info = try container.decode(DownloadInfo.self, forKey: .download)
            guard let scheme = info.url.scheme
            , scheme.lowercased() == "http" || scheme.lowercased() == "https" else {
                throw IronBankKit.Errors.Config.downloadURLInvalid(info)
            }
            self = .download(info)
            return
        } catch DecodingError.dataCorrupted(_) {
            throw IronBankKit.Errors.Config.notYaml
        } catch let IronBankKit.Errors.Config.downloadURLInvalid(info) {
            throw IronBankKit.Errors.Config.downloadURLInvalid(info)
        } catch let DecodingError.keyNotFound(key, context)
            where key.stringValue != CodingKeys.download.stringValue {
                throw DecodingError.keyNotFound(key, context)
        } catch {
        }

        throw IronBankKit.Errors.Config.typeNotSupported
    }

}


