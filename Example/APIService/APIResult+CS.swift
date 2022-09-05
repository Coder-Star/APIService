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
    case invalidParseResponse
}

extension APIResult where T: APIModelWrapper {
    var validateResult: APIValidateResult<T.DataType> {
        var message = "出现错误，请稍后重试"
        switch self {
        case let .success(response):
            if response.code == 200, let data = response.data {
                return .success(data, response.msg)
            } else {
                return .failure(message, APIError.responseError(APIResponseError.invalidParseResponse(CSDataError.invalidParseResponse)))
            }
        case let .failure(apiError):
            if apiError == APIError.networkError {
                message = apiError.localizedDescription
            }

            assertionFailure(apiError.localizedDescription)
            return .failure(message, apiError)
        }
    }
}
