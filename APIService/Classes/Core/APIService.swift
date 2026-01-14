//
//  APIService.swift
//  LTXiOSUtils
//
//  Created by CoderStar on 2021/11/28.
//

import Foundation

/// 回调来源类型
public enum APICompletionHandlerSourceType {
    /// 网络
    case network
    /// 缓存
    case cache
}

/// APICompletionSourceHandler
public typealias APICompletionSourceHandler<T> = (APIResponse<T>, APICompletionHandlerSourceType) -> Void

/// APICompletionHandler
public typealias APICompletionHandler<T> = (APIResponse<T>) -> Void

/// 请求命中缓存回调
public typealias APICacheCompletionHandler<T> = (APIResponse<T>) -> Void

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

    static let `default` = APIService(client: AlamofireAPIClient())
}

// MARK: - 公开属性

extension APIService {
    /// 网络状态
    public var networkStatus: NetworkStatus {
        guard let status = reachabilityManager?.status else {
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
            case .cellular:
                return .wwan
            }
        }
    }

    /// 网络是否可用
    public var isNetworkReachable: Bool {
        return networkStatus == .wifi || networkStatus == .wwan
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
    ///   - cacheHandler: 缓存回调
    ///   - completionHandler: 网络回调
    /// - Returns: 请求任务
    @discardableResult
    public static func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil,
        cacheHandler: APICacheCompletionHandler<T.Response>? = nil,
        completionHandler: APICompletionHandler<T.Response>?
    ) -> APIRequestTask? {
        `default`.sendRequest(
            request,
            plugins: plugins,
            queue: queue,
            progressHandler: progressHandler,
            cacheHandler: cacheHandler,
            completionHandler: completionHandler
        )
    }

    /// 创建数据请求
    /// 这种方式使用为 Alamofire 作为底层实现
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    ///   - completionHandler: 结果回调，包含多种类型
    /// - Returns: 请求任务
    @discardableResult
    public static func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil,
        completionHandler: APICompletionSourceHandler<T.Response>?
    ) -> APIRequestTask? {
        `default`.sendRequest(
            request,
            plugins: plugins,
            queue: queue,
            progressHandler: progressHandler,
            cacheHandler: { response in
                completionHandler?(response, .cache)
            },
            completionHandler: { response in
                completionHandler?(response, .network)
            }
        )
    }
}

extension APIService {
    /// 创建数据请求
    ///
    /// - Parameters:
    ///   - request: 请求
    ///   - plugins: 插件
    ///   - progressHandler: 进度回调
    ///   - cacheHandler: 命中缓存回调
    ///   - completionHandler: 网络回调
    /// - Returns: 请求任务
    @discardableResult
    public func sendRequest<T: APIRequest>(
        _ request: T,
        plugins: [APIPlugin] = [],
        queue: DispatchQueue = .main,
        progressHandler: APIProgressHandler? = nil,
        cacheHandler: APICacheCompletionHandler<T.Response>? = nil,
        completionHandler: APICompletionHandler<T.Response>?
    ) -> APIRequestTask? {
        var resultPlugins = APIConfig.shared.defaultPlugins
        resultPlugins.append(contentsOf: plugins)

        /// 构建 URLRequest
        var urlRequest: URLRequest
        do {
            /// Request拦截器：构建网络请求
            urlRequest = try request.buildURLRequest()

            /// 插件拦截器：构造网络请求
            urlRequest = resultPlugins.reduce(urlRequest) { $1.prepare($0, targetRequest: request) }
        } catch {
            let apiResult: APIResult<T.Response> = .failure(.requestError(error))
            let apiResponse = APIResponse<T.Response>(request: nil, response: nil, data: nil, result: apiResult)
            queue.async { completionHandler?(apiResponse) }
            return nil
        }


        var resultCompletionHandler = completionHandler

        /// 检查缓存
        if let cache = request.cache, cache.usageMode != .none {
            if let cacheTool = APIConfig.shared.cacheTool {
                do {
                    let cachePackage = try cacheTool.getValidObject(byKey: request.cacheKey)

                    let responseModel = try T.Response.parse(data: cachePackage.data)
                    let apiResult: APIResult<T.Response> = .success(responseModel)
                    let apiResponse = APIResponse<T.Response>(request: urlRequest, response: nil, data: cachePackage.data, result: apiResult)
                    queue.async { cacheHandler?(apiResponse) }

                    DebugUtils.log("\(request)命中缓存，缓存key为：\(request.cacheKey)")

                    if cache.usageMode == .cancelNetwork {
                        return nil
                    }

                    if cache.usageMode == .alsoNetwork {
                        resultCompletionHandler = nil
                    }
                } catch {
                    let apiResult: APIResult<T.Response> = .failure(.cache(error))
                    let apiResponse = APIResponse<T.Response>(request: nil, response: nil, data: nil, result: apiResult)
                    queue.async { cacheHandler?(apiResponse) }
                }
            } else {
                assertionFailure("please set cacheStore in APIConfig")
            }
        }

        return sendRequest(
            urlRequest: urlRequest,
            request: request,
            resultPlugins: resultPlugins,
            queue: queue,
            progressHandler: progressHandler,
            completionHandler: resultCompletionHandler
        )
    }

    /// 发起网络请求，不读取缓存
    private func sendRequest<T: APIRequest>(
        urlRequest: URLRequest,
        request: T,
        resultPlugins: [APIPlugin],
        queue: DispatchQueue,
        progressHandler: APIProgressHandler?,
        completionHandler: APICompletionHandler<T.Response>?
    ) -> APIRequestTask? {
        /// 拦截器：即将发送网络请求
        /// 有一个插件不允许发送，则整体不允许发送
        var allowSend = true
        resultPlugins.forEach {
            let result = $0.willSend(urlRequest, targetRequest: request)
            allowSend = result && allowSend
        }

        if !allowSend {
            return nil
        }

        /// 检查网络可达
        if !isNetworkReachable {
            let apiResult: APIResult<T.Response> = .failure(.networkError)
            let apiResponse = APIResponse<T.Response>(request: nil, response: nil, data: nil, result: apiResult)

            /// 插件拦截器：即将回调给业务方
            resultPlugins.forEach { $0.willReceive(apiResponse, targetRequest: request) }

            queue.async { completionHandler?(apiResponse) }

            /// 插件拦截器：回调给业务方之后
            resultPlugins.forEach { $0.didReceive(apiResponse, targetRequest: request) }

            return nil
        }

        let requestTask: APIRequestTask

        switch request.taskType {
        case .request:
            requestTask = client.createDataRequest(request: urlRequest, queue: queue, progressHandler: progressHandler) { [weak self] response in
                let apiResult: APIResult<T.Response>
                switch response.result {
                case let .success(data):
                    do {
                        let responseModel = try T.Response.parse(data: data)
                        apiResult = .success(responseModel)

                        /// 缓存存储
                        if let cache = request.cache, cache.writeNode != .none {
                            if let cacheTool = APIConfig.shared.cacheTool {
                                let cacheAPIResponse = APIResponse<T.Response>(request: response.request, response: response.response, data: response.data, result: apiResult)

                                let allowCache = request.cacheShouldWriteHandler == nil || request.cacheShouldWriteHandler!(cacheAPIResponse)
                                if allowCache {
                                    let cachePackage = APICachePackage(creationDate: Date(), data: data)
                                    cacheTool.set(forKey: request.cacheKey, data: cachePackage, writeMode: cache.writeNode, expiry: cache.expiry, completion: nil)

                                    DebugUtils.log("\(request)缓存写入，缓存key为：\(request.cacheKey)")
                                }

                            } else {
                                assertionFailure("please set cacheStore in APIConfig")
                            }
                        }

                    } catch {
                        apiResult = .failure(.responseError(error))
                    }
                case let .failure(error):
                    apiResult = .failure(.connectionError(error))
                }

                let apiResponse = APIResponse<T.Response>(request: response.request, response: response.response, data: response.data, result: apiResult)
                self?.performData(request: request, response: apiResponse, plugins: resultPlugins, completionHandler: completionHandler)
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
                self?.performData(request: request, response: apiResponse, plugins: resultPlugins, completionHandler: completionHandler)
            }
        case let .upload(file):
            requestTask = client.createUploadRequest(request: urlRequest, file: file, queue: queue, progressHandler: progressHandler) { [weak self] response in
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
                self?.performData(request: request, response: apiResponse, plugins: resultPlugins, completionHandler: completionHandler)
            }
        }

        requestTask.resume()

        return requestTask
    }
}

// MARK: - FormData Upload

extension APIService {}

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
        completionHandler: APICompletionHandler<T.Response>?
    ) {
        /// 插件拦截器：即将回调给业务方
        plugins.forEach { $0.willReceive(response, targetRequest: request) }

        /// Request拦截器：在回调给业务方之前
        request.intercept(request: request, response: response) { replaceResponse in
            completionHandler?(replaceResponse)

            /// 插件拦截器：回调给业务方之后
            plugins.forEach { $0.didReceive(response, targetRequest: request) }
        }
    }
}
