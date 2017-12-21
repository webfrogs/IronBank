//
//  GitRepoInfo.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 21/12/2017.
//

import Foundation

public struct GitRepoInfo: Decodable {
    let remote: String
    let version: String
    let name: String
    let build: BuildType?

    enum CodingKeys: String, CodingKey {
        case remote
        case version
        case name
        case build
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        remote = try values.decode(String.self, forKey: .remote)

        // version is optional.
        do {
            version = try values.decode(String.self, forKey: .version)
                .hand.trimWhitespaceAndNewline()
        } catch {
            version = "master"
        }

        // name is optional.
        do {
            name = try values.decode(String.self, forKey: .name)
        } catch {
            guard let addrURL = URL(string: remote) else {
                throw IronBankKit.Errors.Git.repoNameGenerateFailed(addr: remote)
            }
            var result = addrURL.lastPathComponent
            let trimedSuffix = ".git"
            if result.hasSuffix(trimedSuffix) {
                result = result.hand.substring(to: result.count - trimedSuffix.count)
            }
            name = result
        }

        // build is optional
        var builder: BuildType? = nil
        do {
            builder = try values.decode(XcodeBuilder.self, forKey: .build)
        } catch IronBankKit.Errors.Build.typeNotMatch {
            throw IronBankKit.Errors.Build.typeNotSupport
        } catch let DecodingError.keyNotFound(key, context) {
            // build key is options.
            if key.stringValue != CodingKeys.build.stringValue {
                throw DecodingError.keyNotFound(key, context)
            }
        } catch {
            throw error
        }

        build = builder
    }

    func checkoutFolderPath() throws -> URL {
        let projectCheckoutPath = try IronBankKit.center.gitCheckoutPath()
        let checkoutPath = projectCheckoutPath.appendingPathComponent(name)

        return checkoutPath
    }
}
