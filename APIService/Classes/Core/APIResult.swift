//
//  APIResult.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/4/20.
//

import Foundation

/// 结果
public enum APIResult<T> {
    /// 成功
    case success(T)
    /// 失败
    case failure(APIError)
}

extension APIResult {
    /// 是否成功
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    /// 是否失败
    public var isFailure: Bool {
        return !isSuccess
    }

    /// 值
    public var value: T? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    /// 错误
    public var error: APIError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
