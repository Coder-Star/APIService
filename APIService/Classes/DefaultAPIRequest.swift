//
//  DefaultAPIRequest.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/4/20.
//

import Foundation

public struct DefaultAPIRequest<T: APIParsable>: APIRequest {
    public var baseURL: URL

    public var path: String

    public var method: APIRequestMethod = .get

    public var parameters: [String: Any]?

    public var headers: APIRequestHeaders?

    public var httpBody: Data?

    public var taskType: APIRequestTaskType = .request

    public var encoding: APIParameterEncoding = APIURLEncoding.default

    public typealias Response = T
}

extension DefaultAPIRequest {
    public init(baseURL: URL, path: String, responseType: Response.Type) {
        self.baseURL = baseURL
        self.path = path
    }

    public init<S>(baseURL: URL, path: String, dataType: S.Type) where T: APIModelWrapper, T.DataType == S {
        self.init(baseURL: baseURL, path: path, responseType: T.self)
    }
}
