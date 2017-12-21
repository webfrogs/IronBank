//
//  GitCheckoutInfo.swift
//  IronBank
//
//  Created by Carl Chen on 21/12/2017.
//

import Foundation

struct GitCheckoutInfo {
    let name: String
    let remote: String
    let hash: String

    func resolovedString() -> String {
        return "\(name) --> \(hash)\n\(remote)"
    }
}
