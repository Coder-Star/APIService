//
//  APIModelWrapper.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/27.
//

import Foundation

/// 网络请求结果最外层Model
public protocol APIModelWrapper {
    associatedtype DataType: APIParsable

    var code: Int { get }

    var msg: String { get }

    var data: DataType? { get }
}
