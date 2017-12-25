    //
    //  XcodeBuilder.swift
    //  IronBankPackageDescription
    //
    //  Created by Carl Chen on 13/12/2017.
    //

    import Foundation
    import xcproj

    extension XcodeBuilder {
        func build(item: ConfigItem) throws {
            // clean previous builds
            _ = try? FileManager.default.removeItem(at: p_buildFolderPath())

            // build
            switch item {
            case let .git(info):
                let checkoutPath = try info.checkoutFolderPath()
                guard FileManager.default.fileExists(atPath: checkoutPath.path) else {
                    throw IronBankKit.Errors.Build.projectNotFound
                }

                try p_handleDependency(projectPath: checkoutPath)
                try p_buildProject(path: checkoutPath, name: info.name)

            case let .download(info):
                // TODO: todo
                print(info)
            }
        }
    }

    struct XcodeBuilder: BuildType {

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
            guard type == "Xcode" else {
                throw IronBankKit.Errors.Build.typeNotMatch
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

    private extension XcodeBuilder {
        func p_handleDependency(projectPath: URL) throws {
            // carthage bootstrap --platform xxx --no-use-binaries

            let fileExistChecker: (String) -> Bool = { (filename) in
                return FileManager.default
                    .fileExists(atPath: projectPath.appendingPathComponent(filename).path)
            }



            // Carthage
            if fileExistChecker("Cartfile") {
                // TODO: Check whether carthage is installed.

                // Update
                for buildPlatform in platforms {
                    let shell = "carthage bootstrap --platform "
                        + buildPlatform.rawValue
                        + " --no-use-binaries"

                    var shellEnv = ProcessInfo.processInfo.environment
                    shellEnv["PATH"] = shellEnv["PATH"].map({$0+":/usr/local/bin"}) ?? "/usr/local/bin"
                    let result = Process.ib.syncRun(shell: shell
                        , currentDir: projectPath.path
                        , envrionment: shellEnv)

                    guard result else {
                        throw IronBankKit.Errors.Build.dependencyWrong
                    }

                    if let buildPath = try? p_buildFolderPath()
                        .appendingPathComponent(buildPlatform.rawValue) {
                        try buildPath.ib.createDirectoryIfNotExist()
                        let copyShell = "cp -r Carthage/Build/iOS/*.framework \(buildPath.path) "
                            + "&& cp -r Carthage/Build/iOS/*.dSYM \(buildPath.path)"
                        let copyResult = Process.ib.syncRun(shell: copyShell
                            , currentDir: projectPath.path)
                        guard copyResult else {
                            throw IronBankKit.Errors.Build.dependencyWrong
                        }
                    }

                }
            }

            // Cocoapods
            if fileExistChecker("Podfile") {
                // TODO: check installation of Cocoapods
                let shell = "pod install"

                let result = Process.ib.syncRun(shell: shell, currentDir: projectPath.path)
                guard result else {
                    throw IronBankKit.Errors.Build.dependencyWrong
                }
            }

            // TODO: git submodule


        }

        func p_buildProject(path: URL, name: String) throws {
            let fileEnumertor = FileManager.default.enumerator(at: path
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
                Logger.logError("Find Xcode workspace file, can not build it for now")
                throw IronBankKit.Errors.Build.xcodeWorkspaceNotSupport
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
                    // Only build framework target for now.
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
                let buildOutput = try p_buildFolderPath().appendingPathComponent(platform.rawValue)

                let tempDir = URL(fileURLWithPath: NSTemporaryDirectory())
                    .appendingPathComponent("IronBank")
                    .appendingPathComponent(name)
                try? FileManager.default.removeItem(at: tempDir)
                try tempDir.ib.createDirectoryIfNotExist()

                switch platform {
                case .iOS:
                    let sdkArray = ["iphoneos", "iphonesimulator"]
                    for sdk in sdkArray {
                        let buildShell = "/usr/bin/xcrun xcodebuild "
                            + "-target \(target.name) "
                            + "-configuration release "
                            + "-sdk \(sdk) "
                            + "CONFIGURATION_BUILD_DIR=\"\(tempDir.appendingPathComponent(sdk).path)\" "
                            + "clean build"

                        let result = Process.ib.syncRun(shell: buildShell, currentDir: path.path)

                        guard result else {
                            throw IronBankKit.Errors.Build.buildFailed
                        }
                    }

                    do {
                        let contents = try FileManager.default
                            .contentsOfDirectory(at: tempDir.appendingPathComponent(sdkArray[0])
                                , includingPropertiesForKeys: nil
                                , options: [])

                        var findResult: (framework: URL?, dsym: URL?)
                        for url in contents {
                            switch url.lastPathComponent {
                            case let filename where filename.hasSuffix(".framework"):
                                findResult.framework = url
                            case let filename where filename.hasSuffix(".framework.dSYM"):
                                findResult.dsym = url
                            default:
                                continue
                            }
                        }

                        guard let framework = findResult.framework, let dsym = findResult.dsym else {
                            throw IronBankKit.Errors.Build.buildFailed
                        }
                        let frameworkname = framework.lastPathComponent
                        let dysmFilename = dsym.lastPathComponent

                        let targetName = frameworkname
                            .hand.substring(to: frameworkname.count - ".framework".count)

                        let resultFramework = tempDir.appendingPathComponent(frameworkname)
                        let resultDYSM = tempDir.appendingPathComponent(dysmFilename)
                        try FileManager.default.copyItem(at: framework, to: resultFramework)
                        try FileManager.default.copyItem(at: dsym, to: resultDYSM)

                        // Copy swiftmodule files.
                        let moduleFilePath = "Modules/" + targetName + ".swiftmodule"
                        let simularBuildPath = tempDir
                            .appendingPathComponent(sdkArray[1])
                            .appendingPathComponent(frameworkname)
                        let swiftModuleFileFolder = simularBuildPath
                            .appendingPathComponent(moduleFilePath)
                        let copyShell = "cp \(swiftModuleFileFolder.path)/* "
                            + "\(resultFramework.path)/\(moduleFilePath)"
                        guard Process.ib.syncRun(shell: copyShell) else {
                            throw IronBankKit.Errors.Build.buildFailed
                        }

                        // merge binary with different architectures.
                        let resultBinaryPath = resultFramework.appendingPathComponent(targetName).path
                        let mergeBinShell = "lipo -create \(resultBinaryPath) "
                            + simularBuildPath.appendingPathComponent(targetName).path
                            + " -o \(resultBinaryPath)"
                        guard Process.ib.syncRun(shell: mergeBinShell) else {
                            throw IronBankKit.Errors.Build.buildFailed
                        }

                        // TODO: merge DYSM file



                    } catch {
                        throw IronBankKit.Errors.Build.buildFailed
                    }


                default:
                    // TODO: Add support to simular if platform is tvOS or watchOS.
                    let buildShell = "/usr/bin/xcrun xcodebuild "
                        + "-target \(target.name) "
                        + "-configuration release "
                        + "CONFIGURATION_BUILD_DIR=\"\(buildOutput.path)\" "
                        + "clean build"

                    let result = Process.ib.syncRun(shell: buildShell, currentDir: path.path)

                    guard result else {
                        throw IronBankKit.Errors.Build.buildFailed
                    }

                }

            }
        }

        func p_buildFolderPath() throws -> URL {
            return try IronBankKit.center.buildFolderPath().appendingPathComponent("Xcode")
        }

    }
