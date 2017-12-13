//
//  Build.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 10/12/2017.
//

import Foundation

protocol BuildType: Codable {
    func build(item: ConfigItem) throws
}

