//
//  APIError.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2022/3/25.
//

import Foundation

/// APIError
public enum APIError: LocalizedError {
    /// 网络错误
    case networkError

    /// 发送错误
    case requestError(Error)

    /// 连接错误
    case connectionError(Error)

    /// 接收错误
    /// 解析等步骤
    case responseError(Error)

    public var errorDescription: String? {
        switch self {
        case let .requestError(error):
            return "发出请求错误（\(error.localizedDescription)）"
        case let .connectionError(error):
            return "请求错误（\(error.localizedDescription)）"
        case let .responseError(error):
            return "结果处理错误（\(error.localizedDescription)）"
        case .networkError:
            return "当前网络不可用"
        }
    }
}

extension APIError: Equatable {
    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        return "\(lhs)" == "\(rhs)"
    }
}

/// APIRequestError
public enum APIRequestError: LocalizedError {
    /// 不合理的请求链接
    case invalidURLRequest

    public var errorDescription: String? {
        switch self {
        case .invalidURLRequest:
            return "不合理的请求链接"
        }
    }
}

/// APIResponseError
public enum APIResponseError: LocalizedError {
    /// 无法正确解析Response
    case invalidParseResponse(Error)

    public var errorDescription: String? {
        switch self {
        case let .invalidParseResponse(error):
            return error.localizedDescription
        }
    }
}
