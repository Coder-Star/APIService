//
//  APIParsable.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/4.
//

import Foundation

// MARK: - APIParsable

/// 解析角色
public protocol APIParsable {
    /// 将 Data 解析成 Model
    /// - Parameter data: data
    /// - Returns: Model
    static func parse(data: Data) throws -> Self
}

extension Data: APIParsable {
    /// Data默认实现解析协议
    /// 使请求时可以请求Data数据，业务方自己根据实际情况进行解析
    ///
    /// - Parameter data: data
    /// - Returns: 还是data
    public static func parse(data: Data) throws -> Self {
        return data
    }
}

// MARK: - APIJSONParsable

/// JSON解析角色
public protocol APIJSONParsable: APIParsable {}

extension APIJSONParsable where Self: Decodable {
    /// APIJSONParsable 默认实现
    /// 使用 JSONDecoder 的方式
    ///
    /// - Parameter data: data
    /// - Returns: 解析结果
    public static func parse(data: Data) throws -> Self {
        do {
            let model = try JSONDecoder().decode(self, from: data)
            return model
        } catch {
            throw APIResponseError.invalidParseResponse(error)
        }
    }
}

/// 如果使用默认方式Decodable进行解析，最外层Model就可以直接实现该协议
public typealias APIDefaultJSONParsable = APIJSONParsable & Decodable

// MARK: - 默认实现

extension String: APIParsable {}

extension String: APIJSONParsable {}

extension Array: APIParsable where Array.Element: APIDefaultJSONParsable {}

extension Array: APIJSONParsable where Element: APIDefaultJSONParsable {}
