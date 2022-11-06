//
//  CSAPIRequest.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/11/6.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import Foundation

class CSAPIRequest<DataResponse: APIDefaultJSONParsable>: APIRequest {
    typealias Response = CSBaseResponseModel<DataResponse>

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

    var path: String {
        return ""
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

    var isMock: Bool {
        return false
    }

    /// 验证码
    private var neteaseValidate = ""

    func intercept(parameters: [String: Any]?) -> [String: Any]? {
        if !neteaseValidate.isEmpty {
            var resultParameters = parameters ?? [:]
            resultParameters["neteaseValidate"] = neteaseValidate
            return resultParameters
        } else {
            return parameters
        }
    }

    func intercept<U: APIRequest>(request: U, response: APIResponse<Response>, replaceResponseHandler: @escaping APICompletionHandler<Response>) {
        if response.result.value?.code == 1001, let csAPIRequest = request as? CSAPIRequest {
            csAPIRequest.neteaseValidate = "123"
            APIService.sendRequest(csAPIRequest, completionHandler: replaceResponseHandler)
        }
        replaceResponseHandler(response)
    }
}
