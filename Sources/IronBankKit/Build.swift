//
//  Build.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 10/12/2017.
//

import Foundation
import xcproj

protocol BuildType: Codable {
    func build(item: ConfigItem) throws
}

extension XcodeBuild {
    func build(item: ConfigItem) throws {
        switch item {
        case let .git(info):
            let checkoutPath = try info.checkoutFolderPath()
            guard FileManager.default.fileExists(atPath: checkoutPath.path) else {
                throw IronBankKit.Errors.Build.projectNotFound
            }

            let fileEnumertor = FileManager.default.enumerator(at: checkoutPath
                , includingPropertiesForKeys: [URLResourceKey.isDirectoryKey]
                , options: [.skipsSubdirectoryDescendants])

            var fileList: [URL] = []
            while let file = fileEnumertor?.nextObject() as? URL {
                fileList.append(file)
            }

            let projectFiles = fileList.filter({ (url) -> Bool in
                return url.lastPathComponent.hasSuffix(".xcodeproj")
            })
            let workspaceFiles = fileList.filter({ (url) -> Bool in
                return url.lastPathComponent.hasSuffix(".xcworkspace")
            })

            if workspaceFiles.count > 0 {
                // TODO: todo
                print("Find Xcode workspace.")
            }

            guard let projectPath = projectFiles.first else {
                throw IronBankKit.Errors.Build.projectNotFound
            }

            let project: XcodeProj
            do {
                project = try XcodeProj(pathString: projectPath.path)
            } catch {
                throw IronBankKit.Errors.Build.projectCannotParsed
            }


            var targetsToBuild: [(platform: Platform, target: PBXNativeTarget)] = []

            for (_, target) in project.pbxproj.objects.nativeTargets {
                guard target.productType == PBXProductType.framework else {
                    // Only build framework.
                    continue
                }

                guard let configListID = target.buildConfigurationList
                , let configList = project.pbxproj.objects.configurationLists[configListID] else {
                        continue
                }

                for buildConfigID in configList.buildConfigurations {
                    guard let buildConfig = project.pbxproj
                        .objects.buildConfigurations[buildConfigID] else {
                            continue
                    }

                    // Find release configuration.
                    guard buildConfig.name == "Release" else {
                        continue
                    }

                    // xcproj don't parse the 'SDKROOT' when target is iOS, so add it manually.
                    // Don't know why, maybe it is a bug in xcproj.
                    let sdkRoot = (buildConfig.buildSettings["SDKROOT"] as? String) ?? "iphoneos"
                    guard let platform = Platform(sdkRoot: sdkRoot) else {
                        continue
                    }

                    if self.platforms.contains(platform) {
                        targetsToBuild.append((platform, target))
                    }
                }
            }

            for (platform, target) in targetsToBuild {
                let buildOutput = try IronBankKit.center.buildFolderPath()
                    .appendingPathComponent("Xcode")
                    .appendingPathComponent(platform.rawValue)
                    .appendingPathComponent(info.name)

                let buildShell = "/usr/bin/xcrun xcodebuild "
                    + "-target \(target.name) "
                    + "-configuration release "
                    + "CONFIGURATION_BUILD_DIR=\"\(buildOutput.path)\" "
                    + "clean build"

                let result = Process.ib.syncRun(shell: buildShell, currentDir: checkoutPath.path)

                guard result == EX_OK else {
                    throw IronBankKit.Errors.Build.buildFailed
                }
            }

        case let .download(info):
            // TODO: todo
            print(info)
        }
    }
}

struct XcodeBuild: BuildType {

    enum Platform: String {
        case iOS
        case macOS
        case tvOS

        init?(sdkRoot: String) {
            switch sdkRoot {
            case let txt where txt.hasPrefix("iphoneos"):
                self = .iOS
            case let txt where txt.hasPrefix("macosx"):
                self = .macOS
            case let txt where txt.hasPrefix("appletvos"):
                self = .tvOS
            default:
                return nil
            }
        }
    }

    let platforms: [Platform]

    enum CodingKeys: String, CodingKey {
        case type
        case platforms
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let type = try container.decode(String.self, forKey: .type)
        guard type == "xcode" else {
            throw IronBankKit.Errors.Build.typeInvalid
        }

        platforms = try container.decode([String].self, forKey: .platforms)
            .map({ (text) -> Platform in
                guard let result = Platform(rawValue: text) else {
                    throw IronBankKit.Errors.Build
                        .configInfoWrong("Platform \(text) is not supported. ")
                }
                return result
            })

    }

    func encode(to encoder: Encoder) throws {

    }
}
