//
//  APIResult.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/4/20.
//

import Foundation

/// 结果
public enum APIResult<T> {
    case success(T)
    case failure(APIError)
}

extension APIResult {
    public var isSuccess: Bool {
        switch self {
        case .success:
            return true
        case .failure:
            return false
        }
    }

    public var isFailure: Bool {
        return !isSuccess
    }

    public var value: T? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }

    public var error: APIError? {
        switch self {
        case .success:
            return nil
        case .failure(let error):
            return error
        }
    }
}
