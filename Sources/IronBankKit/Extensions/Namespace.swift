//
//  Namespace.swift
//  IronBankPackageDescription
//
//  Created by Carl Chen on 07/12/2017.
//

import Foundation

public protocol NamespaceWrappable {
    associatedtype IronBankWrapperType
    var ib: IronBankWrapperType { get }
    static var ib: IronBankWrapperType.Type { get }
}

public extension NamespaceWrappable {
    var ib: NamespaceWrapper<Self> {
        return NamespaceWrapper(value: self)
    }

    static var ib: NamespaceWrapper<Self>.Type {
        return NamespaceWrapper.self
    }
}

public struct NamespaceWrapper<T> {
    public let wrappedValue: T
    public init(value: T) {
        self.wrappedValue = value
    }
}
