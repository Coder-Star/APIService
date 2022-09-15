//
//  CSAPIRequest.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/4/29.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import Foundation

protocol CSAPIRequest: APIRequest where Response == CSBaseResponseModel<DataResponse> {
    associatedtype DataResponse: Decodable

    var isMock: Bool { get }
}

extension CSAPIRequest {
    var isMock: Bool {
        return false
    }

    var baseURL: URL {
        if isMock {
            return NetworkConstants.baseMockURL
        }
        switch NetworkConstants.env {
        case .prod:
            return NetworkConstants.baseProdURL
        case .dev:
            return NetworkConstants.baseDevURL
        }
    }

    var method: APIRequestMethod { .get }


    var parameters: [String: Any]? {
        return nil
    }

    var headers: APIRequestHeaders? {
        return nil
    }

    var taskType: APIRequestTaskType {
        return .request
    }

    var encoding: APIParameterEncoding {
        return APIURLEncoding.default
    }

    public func intercept(urlRequest: URLRequest) throws -> URLRequest {
        return urlRequest
    }

    public func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        replaceResponseHandler(response)
    }
}
