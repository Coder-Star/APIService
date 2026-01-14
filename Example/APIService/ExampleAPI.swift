//
//  ExampleAPI.swift
//  APIService_Example
//
//  Created by CoderStar on 2022/9/15.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import APIService
import Foundation

enum ExampleAPI {}

extension ExampleAPI {
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
}

extension ExampleAPI {
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
}

extension ExampleAPI {
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
            // 多次回调模式
            cache.usageMode = .alsoNetworkWithCallback
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

extension ExampleAPI {
    /// 下载请求示例
    struct DownloadRequest: CSAPIRequestProtocol {
        typealias DataResponse = PlaceholderResponseModel
        
        let downloadURL: URL
        let callback: ((String) -> Void)
        
        var url: URL? {
            return downloadURL
        }
        
        var path: String {
            return ""
        }

        var parameters: [String: Any]? {
            return nil
        }

        var taskType: APIRequestTaskType {
            return .download { temporaryURL, response in
                let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                let fileName = response.suggestedFilename ?? "\(UUID().uuidString).file"
                let destinationURL = documentsURL.appendingPathComponent("Downloads").appendingPathComponent(fileName)
                self.callback(destinationURL.path)
                return (destinationURL, [.createIntermediateDirectories, .removePreviousFile])
            }
        }
    }
}
