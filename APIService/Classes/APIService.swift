//
//  APIService.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2021/11/28.
//

import Foundation

/// APICompletionHandler
public typealias APICompletionHandler<T> = (APIResponse<T>) -> Void

/// 网络状态
public enum NetworkStatus {
    /// 未知
    case unknown
    /// 不可用
    case notReachable
    /// wifi
    case wifi
    /// 数据
    case wwan
}

// MARK: - APIService

/// API服务
open class APIService {
    private let reachabilityManager = APINetworkReachabilityManager()

    /// 发送者
    public let clinet: APIClient

    /// 构造方法
    /// - Parameter clinet: 发送者实现
    public init(clinet: APIClient) {
        self.clinet = clinet
    }

    private static let `default` = APIService(clinet: AlamofireAPIClient())
}

// MARK: - 公开属性

extension APIService {
    /// 网络状态
    public var networkStatus: NetworkStatus {
        guard let status = reachabilityManager?.networkReachabilityStatus else {
            return .unknown
        }
        switch status {
        case .unknown:
            return .unknown
        case .notReachable:
            return .notReachable
        case let .reachable(type):
            switch type {
            case .ethernetOrWiFi:
                return .wifi
            case .wwan:
                return .wwan
            }
        }
    }

    /// 网络是否可用
    public var isNetworkReachable: Bool {
        return networkStatus == .wifi || networkStatus == .wwan
    }
}

// MARK: - 私有方法

extension APIService {
    /// 回调数据给调用方
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - response: 上层回来的数据
    ///   - result: 结果
    ///   - plugins: 插件
    ///   - completionHandler: 结果回调
    /// - Returns: 请求任务
    private func performdData<T: APIRequest>(
        request: T,
        response: APIResponse<T.Response>,
        plugins: [APIPlugin],
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) {
        plugins.forEach { $0.willReceive(response, targetRequest: request) }

        request.intercept(request: request, response: response) { replaceResponse in
            completionHandler(replaceResponse)
            plugins.forEach { $0.didReceive(response, targetRequest: request) }
        }
    }
}

// MARK: - 公开方法

extension APIService {
    /// 创建数据请求
    /// 这种方式使用为 Alamofire 作为底层实现
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 结果回调
    /// - Returns: 请求任务
    @discardableResult
    public static func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        encoding: APIParameterEncoding? = nil,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) -> APIRequestTask? {
        `default`.sendRequest(request, plugins: plugins, encoding: encoding, progressHandler: progressHandler, completionHandler: completionHandler)
    }

    /// 创建数据请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 结果回调
    /// - Returns: 请求任务
    @discardableResult
    public func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        encoding: APIParameterEncoding? = nil,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) -> APIRequestTask? {
        var urlRequest: URLRequest

        do {
            urlRequest = try request.buildURLRequest(encoding: encoding)
            urlRequest = plugins.reduce(urlRequest) { $1.prepare($0, targetRequest: request) }
        } catch {
            let apiResult: APIResult<T.Response> = .failure(.requestError(error))
            let apiResponse = APIResponse<T.Response>(request: nil, response: nil, data: nil, result: apiResult)
            completionHandler(apiResponse)
            return nil
        }

        if !isNetworkReachable {
            let apiResult: APIResult<T.Response> = .failure(.networkError)
            let apiResponse = APIResponse<T.Response>(request: nil, response: nil, data: nil, result: apiResult)
            completionHandler(apiResponse)
            return nil
        }

        let requestTask: APIRequestTask

        plugins.forEach { $0.willSend(urlRequest, targetRequest: request) }

        switch request.taskType {
        case .request:
            requestTask = clinet.createDataRequest(request: urlRequest, progressHandler: progressHandler) { [weak self] response in
                let apiResult: APIResult<T.Response>
                switch response.result {
                case let .success(data):
                    do {
                        let responseModel = try T.Response.parse(data: data)
                        apiResult = .success(responseModel)
                    } catch {
                        apiResult = .failure(.responseError(error))
                    }
                case let .failure(error):
                    apiResult = .failure(.connectionError(error))
                }

                let apiResponse = APIResponse<T.Response>(request: response.request, response: response.response, data: response.data, result: apiResult)
                self?.performdData(request: request, response: apiResponse, plugins: plugins, completionHandler: completionHandler)
            }
        case let .download(apiDownloadDestination):
            requestTask = clinet.createDownloadRequest(request: urlRequest, to: apiDownloadDestination, progressHandler: progressHandler) { [weak self] response in
                let apiResult: APIResult<T.Response>
                switch response.result {
                case let .success(data):
                    do {
                        let responseModel = try T.Response.parse(data: data)
                        apiResult = .success(responseModel)
                    } catch {
                        apiResult = .failure(.responseError(error))
                    }
                case let .failure(error):
                    apiResult = .failure(.connectionError(error))
                }

                let apiResponse = APIResponse<T.Response>(request: response.request, response: response.response, data: response.value, result: apiResult)
                self?.performdData(request: request, response: apiResponse, plugins: plugins, completionHandler: completionHandler)
            }
        }
        requestTask.resume()
        return requestTask
    }
}

// MARK: - FormData Upload

extension APIService {}
