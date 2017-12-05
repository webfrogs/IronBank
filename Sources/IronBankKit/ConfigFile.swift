//
//  ConfigFile.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 05/12/2017.
//

import Foundation
import HandOfTheKing

public protocol ConfigFileType {
    init(path: String) throws

    func update()
}

public struct ConfigFileFactory {
    public static func newModel(path: String) throws -> ConfigFileType {
        return try ConfigFile(path: path)
    }
}


public enum ConfigFileErrors: Error {
    case fileNotExist
    case contentInvalid
    case typeNotSupported(String)
}

public enum ConfigItem {
    case git(remote: String)
    case download(url: String)
    
    init(configLine: String) throws {
        guard let firstSpaceIndex = configLine.index(of: " ") else {
            throw ConfigFileErrors.contentInvalid
        }
        let type = configLine[configLine.startIndex..<firstSpaceIndex]

        var indexString = configLine[configLine.index(firstSpaceIndex, offsetBy: 1)...]
        guard let firstQuotationMarkIndex = indexString.index(of: "\"") else {
            throw ConfigFileErrors.contentInvalid
        }

        indexString = indexString[indexString.index(firstQuotationMarkIndex, offsetBy: 1)...]
        guard let secondQuotationMarkIndex = indexString.index(of: "\"") else {
            throw ConfigFileErrors.contentInvalid
        }
        let url = String(indexString[..<secondQuotationMarkIndex])
        
        switch type {
        case "git":
            self = .git(remote: url)
        case "download":
            self = .download(url: url)
        default:
            throw ConfigFileErrors.typeNotSupported(String(type))
        }
    }
}

struct ConfigFile: ConfigFileType {
    let items: [ConfigItem]
    
    init(path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw ConfigFileErrors.fileNotExist
        }
        
        let fileContent: String
        do {
            fileContent = try String(contentsOfFile: path, encoding: String.Encoding.utf8)
        } catch {
            throw ConfigFileErrors.contentInvalid
        }
        
        do {
            items = try fileContent.components(separatedBy: "\n")
                .map({ (line) -> ConfigItem in
                    try ConfigItem.init(configLine: line)
                })
        } catch {
            throw error
        }
        
    }
}

extension ConfigFile {
    func update() {

    }
}
