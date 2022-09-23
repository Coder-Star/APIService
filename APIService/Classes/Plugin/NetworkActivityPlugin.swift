//
//  NetworkActivityPlugin.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/22.
//

import Foundation

public enum NetworkActivityChangeType {
    case began
    case ended
}

public struct NetworkActivityPlugin {
    public typealias NetworkActivityClosure = (_ change: NetworkActivityChangeType) -> Void
    let networkActivityClosure: NetworkActivityClosure

    public init(networkActivityClosure: @escaping NetworkActivityClosure) {
        self.networkActivityClosure = networkActivityClosure
    }
}

extension NetworkActivityPlugin: APIPlugin {
    public func willSend<T>(_ request: URLRequest, targetRequest: T) -> Bool where T: APIRequest {
        networkActivityClosure(.began)
        return true
    }

    public func willReceive<T>(_ result: APIResponse<T.Response>, targetRequest: T) where T: APIRequest {
        networkActivityClosure(.ended)
    }
}
