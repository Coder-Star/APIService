//
//  CSAPIRequest.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/4/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import Foundation

public struct CSAPIRequest<T: APIParsable>: APIRequest {
    public let baseURL: URL

    public let path: String

    public var method: APIRequestMethod = .get

    public var parameters: [String: Any]?

    public var headers: APIRequestHeaders?

    public var taskType: APIRequestTaskType = .request

    public var encoding: APIParameterEncoding = APIURLEncoding.default

    public typealias Response = T
}

// MARK: - 构造函数

extension CSAPIRequest {
    public init<S>(path: String, dataType: S.Type) where CSBaseResponseModel<S> == T {
        self.baseURL = NetworkConstants.baseURL

        self.path = path
    }
}

// MARK: - 协议方法

extension CSAPIRequest {
    public func intercept(urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    public func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        replaceResponseHandler(response)
    }
}
