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
    public let client: APIClient

    /// 构造方法
    /// - Parameter client: 发送者实现
    public init(client: APIClient) {
        self.client = client
    }

    private static let `default` = APIService(client: AlamofireAPIClient())
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
    private func performData<T: APIRequest>(
        request: T,
        response: APIResponse<T.Response>,
        plugins: [APIPlugin],
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) {
        /// 插件拦截器：即将回调给业务方
        plugins.forEach { $0.willReceive(response, targetRequest: request) }

        /// Request拦截器：在回调给业务方之前
        request.intercept(request: request, response: response) { replaceResponse in
            completionHandler(replaceResponse)

            /// 插件拦截器：回调给业务方之后
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
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) -> APIRequestTask? {
        `default`.sendRequest(request, plugins: plugins, queue: queue, progressHandler: progressHandler, completionHandler: completionHandler)
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
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: @escaping APICompletionHandler<T.Response>
    ) -> APIRequestTask? {
        var urlRequest: URLRequest

        do {
            /// Request拦截器：构建网络请求
            urlRequest = try request.buildURLRequest()

            /// 插件拦截器：构造网络请求
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

        /// 拦截器：即将发送网络请求
        plugins.forEach { $0.willSend(urlRequest, targetRequest: request) }

        switch request.taskType {
        case .request:
            requestTask = client.createDataRequest(request: urlRequest, queue: queue, progressHandler: progressHandler) { [weak self] response in
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
                self?.performData(request: request, response: apiResponse, plugins: plugins, completionHandler: completionHandler)
            }
        case let .download(apiDownloadDestination):
            requestTask = client.createDownloadRequest(request: urlRequest, to: apiDownloadDestination, queue: queue, progressHandler: progressHandler) { [weak self] response in
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
                self?.performData(request: request, response: apiResponse, plugins: plugins, completionHandler: completionHandler)
            }
        }
        requestTask.resume()
        return requestTask
    }
}

// MARK: - FormData Upload

extension APIService {}
