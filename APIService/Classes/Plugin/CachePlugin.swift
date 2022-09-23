//
//  CachePlugin.swift
//  CSAPIService
//
//  Created by CoderStar on 2022/9/22.
//

import Foundation

public struct CachePlugin<S: APIRequest> {
    public init() {}

    public var cache: APICache?

    public var queue: DispatchQueue?

    public var cacheHandler: APICacheCompletionHandler<S.Response>?
}

extension CachePlugin: APIPlugin {
    public func willSend<T: APIRequest>(_ request: URLRequest, targetRequest: T) -> Bool {
        if let cache = cache {
            if let cacheTool = APIConfig.shared.cacheTool {
                if cache.readMode != .none {
                    do {
                        let cachePackage = try cacheTool.getValidObject(byKey: targetRequest.cacheKey)

                        let responseModel = try S.Response.parse(data: cachePackage.data)

                        let apiResult: APIResult<S.Response> = .success(responseModel)
                        let apiResponse = APIResponse<S.Response>(request: request, response: nil, data: cachePackage.data, result: apiResult)
                        (queue ?? DispatchQueue.main).async { cacheHandler?(apiResponse) }

                        if cache.readMode != .alsoNetwork {
                            return false
                        }
                    } catch {
                        let apiResult: APIResult<S.Response> = .failure(.cache(error))
                        let apiResponse = APIResponse<S.Response>(request: nil, response: nil, data: nil, result: apiResult)
                        (queue ?? DispatchQueue.main).async { cacheHandler?(apiResponse) }
                    }
                }
            } else {
                assertionFailure("please set cacheStore in APIConfig")
            }
        }

        return true
    }

    public func willReceive<T: APIRequest>(_ result: APIResponse<T.Response>, targetRequest: T) {
        if case let .success(data) = result.result {
            /// 缓存存储
            if let cache = targetRequest.cache, cache.writeNode != .none, let data = result.data {
                if let cacheTool = APIConfig.shared.cacheTool {
                    let allowCache = cache.shouldCacheHandler == nil || cache.shouldCacheHandler!(result.response, result.data)
                    if allowCache {
                        let cachePackage = APICachePackage(creationDate: Date(), data: data)
                        cacheTool.set(forKey: targetRequest.cacheKey, data: cachePackage, writeMode: cache.writeNode, expiry: cache.expiry, completion: nil)
                    }

                } else {
                    assertionFailure("please set cacheStore in APIConfig")
                }
            }
        }
    }
}
