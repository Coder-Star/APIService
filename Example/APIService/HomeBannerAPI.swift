//
//  HomeBannerAPI.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import Foundation

enum HomeBannerAPI {
    struct HomeBannerRequest: CSAPIRequestProtocol {
        typealias DataResponse = HomeBanner

        var parameters: [String: Any]? {
            return [
                "param1": "张三",
                "param2": "18",
            ]
        }

        var path: String {
            return "/config/homeBanner"
        }

        var cache: APICache? {
            var cache = APICache()
            cache.usageMode = .alsoNetwork
            cache.writeNode = .memoryAndDisk
            cache.expiry = .seconds(10)
            return cache
        }

        var cacheFilterParameters: [String] {
            return ["param1"]
        }

        var cacheShouldWriteHandler: ((APIResponse<CSBaseResponseModel<DataResponse>>) -> Bool)? = { response in
            if response.result.isSuccessCode, response.result.value?.data != nil {
                return true
            }
            return false
        }
    }

    class LaunchAdRequest: CSAPIRequest<LaunchAd> {
        override var parameters: [String: Any]? {
            return [
                "param1": "张三",
                "param2": "18",
            ]
        }

        override var path: String {
            return "/config/launchAd"
        }

        deinit {
            debugPrint("LaunchAdRequest deinit")
        }
    }

    /// 用于演示 AsyncSequence 多次回调的请求（alsoNetworkWithCallback 模式）
    struct MultipleCallbackRequest: CSAPIRequestProtocol {
        typealias DataResponse = HomeBanner

        var parameters: [String: Any]? {
            return [
                "param1": "张三",
                "param2": "18",
            ]
        }

        var path: String {
            return "/config/homeBanner"
        }

        var cache: APICache? {
            var cache = APICache()
            cache.usageMode = .alsoNetworkWithCallback  // 多次回调模式
            cache.writeNode = .memoryAndDisk
            cache.expiry = .seconds(10)
            return cache
        }

        var cacheFilterParameters: [String] {
            return ["param1"]
        }

        var cacheShouldWriteHandler: ((APIResponse<CSBaseResponseModel<DataResponse>>) -> Bool)? = { response in
            if response.result.isSuccessCode, response.result.value?.data != nil {
                return true
            }
            return false
        }
    }
}
