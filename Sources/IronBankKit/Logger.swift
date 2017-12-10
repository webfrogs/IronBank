//
//  Logger.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 10/12/2017.
//

import Foundation
import Rainbow

public struct Logger {
    public enum Level {
        case warning
        case info
        case error
    }

    public static func log(_ txt: String, level: Level) {
        switch level {
        case .info:
            print(txt.green)
        case .warning:
            print(txt.yellow)
        case .error:
            print(txt.red)
        }
    }

    public static func logInfo(_ txt: String) {
        log(txt, level: .info)
    }

    public static func logWarning(_ txt: String) {
        log(txt, level: .warning)
    }

    public static func logError(_ txt: String) {
        log(txt, level: .error)
    }

}
