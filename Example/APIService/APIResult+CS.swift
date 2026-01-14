//
//  APIResult+CS.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/5/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService

public enum APIValidateResult<T> {
    case success(T, String)
    case failure(String, APIError)
}

public enum CSDataError: Error {
    case invalidCode
    case invalidParseResponse
}

extension APIResult where T: APIModelWrapper {
    /// 业务校验器，可根据业务定制
    var validateResult: APIValidateResult<T.DataType> {
        var message = "出现错误，请稍后重试"
        switch self {
        case let .success(response):
            if checkSuccessCode(code: response.code) {
                if let data = response.data {
                    return .success(data, response.msg)
                } else {
                    return .failure(message, APIError.responseError(CSDataError.invalidParseResponse))
                }
            } else {
                return .failure(message, APIError.responseError(CSDataError.invalidCode))
            }
        case let .failure(apiError):
            if apiError == APIError.networkError {
                message = apiError.localizedDescription
            }

            assertionFailure(apiError.localizedDescription)
            return .failure(message, apiError)
        }
    }

    var isSuccessCode: Bool {
        return checkSuccessCode(code: value?.code)
    }

    private func checkSuccessCode(code: Int?) -> Bool {
        return code == 200
    }
}


// 扩展 APIResponse
extension APIResponse where T: APIModelWrapper {
    @discardableResult
    func validated() throws -> (T.DataType, String) {
        switch result.validateResult {
        case let .success(data, msg):
            return (data, msg)
        case let .failure(_, error):
            throw error
        }
    }
    
    var validatedValue: T.DataType {
        get throws {
            try validated().0
        }
    }
}
